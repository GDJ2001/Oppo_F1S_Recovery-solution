#!/usr/bin/env python3
"""Extract OPPO/Realme MediaTek OFP packages.

The extractor parses the MTK OFP footer/index, validates the AES key against
the embedded scatter entry, then decrypts each entry's encrypted prefix and
copies the remaining plain bytes.
"""

from __future__ import annotations

import argparse
import hashlib
from binascii import hexlify, unhexlify
from pathlib import Path
from struct import unpack

from Cryptodome.Cipher import AES


HEADER_KEY = bytearray(b"geyixue")
HEADER_LENGTH = 0x6C
ENTRY_LENGTH = 0x60
READ_CHUNK = 0x200000

KEY_TABLES = [
    ("67657963787565E837D226B69A495D21", "F6C50203515A2CE7D8C3E1F938B7E94C", "42F2D5399137E2B2813CD8ECDF2F4D72"),
    ("9E4F32639D21357D37D226B69A495D21", "A3D8D358E42F5A9E931DD3917D9A3218", "386935399137416B67416BECF22F519A"),
    ("892D57E92A4D8A975E3C216B7C9DE189", "D26DF2D9913785B145D18C7219B89F26", "516989E4A1BFC78B365C6BC57D944391"),
    ("27827963787265EF89D126B69A495A21", "82C50203285A2CE7D8C3E198383CE94C", "422DD5399181E223813CD8ECDF2E4D72"),
    ("3C4A618D9BF2E4279DC758CD535147C3", "87B13D29709AC1BF2382276C4E8DF232", "59B7A8E967265E9BCABE2469FE4A915E"),
    ("1C3288822BF824259DC852C1733127D3", "E7918D22799181CF2312176C9E2DF298", "3247F889A7B6DECBCA3E28693E4AAAFE"),
    ("1E4F32239D65A57D37D2266D9A775D43", "A332D3C3E42F5A3E931DD991729A321D", "3F2A35399A373377674155ECF28FD19A"),
    ("122D57E92A518AFF5E3C786B7C34E189", "DD6DF2D9543785674522717219989FB0", "12698965A132C76136CC88C5DD94EE91"),
    ("ab3f76d7989207f2", "2bf515b3a9737835"),
]


def _shuffle_nibble(value: int) -> int:
    return ((value & 0xF) << 4) + ((value & 0xF0) >> 4)


def _mtk_shuffle(key: bytes | bytearray, data: bytearray) -> bytearray:
    for index, value in enumerate(data):
        data[index] = key[index % len(key)] ^ _shuffle_nibble(value)
    return data


def _mtk_shuffle_for_key(key: bytes | bytearray, data: bytearray) -> bytearray:
    for index, value in enumerate(data):
        data[index] = _shuffle_nibble(key[index % len(key)] ^ value)
    return data


def _clean_c_string(raw: bytes) -> str:
    return raw.split(b"\x00", 1)[0].decode("utf-8", errors="replace")


def _derive_key(table: tuple[str, ...]) -> tuple[bytes, bytes]:
    if len(table) == 2:
        return table[0].encode("ascii"), table[1].encode("ascii")

    obfuscation = bytearray(unhexlify(table[0]))
    encrypted_key = bytearray(unhexlify(table[1]))
    encrypted_iv = bytearray(unhexlify(table[2]))
    key = hexlify(hashlib.md5(_mtk_shuffle_for_key(obfuscation, encrypted_key)).digest())[:16]
    iv = hexlify(hashlib.md5(_mtk_shuffle_for_key(obfuscation, encrypted_iv)).digest())[:16]
    return key, iv


def _decrypt_prefix(key: bytes, iv: bytes, data: bytes) -> bytes:
    padded = data
    if len(padded) % 16:
        padded += b"\x00" * (16 - (len(padded) % 16))
    decrypted = AES.new(key, AES.MODE_CFB, IV=iv, segment_size=128).decrypt(padded)
    return decrypted[: len(data)]


def _parse_entries(ofp_path: Path) -> tuple[dict[str, str | int], list[dict[str, str | int]]]:
    size = ofp_path.stat().st_size
    with ofp_path.open("rb") as handle:
        handle.seek(size - HEADER_LENGTH)
        header = _mtk_shuffle(HEADER_KEY, bytearray(handle.read(HEADER_LENGTH)))
        project, unknown, reserved, cpu, flash, count, project_info, crc = unpack("46s Q 4s 7s 5s H 32s H", header)
        handle.seek(size - (count * ENTRY_LENGTH) - HEADER_LENGTH)
        entry_data = _mtk_shuffle(HEADER_KEY, bytearray(handle.read(count * ENTRY_LENGTH)))

    package = {
        "project": _clean_c_string(project),
        "unknown": unknown,
        "reserved": _clean_c_string(reserved),
        "cpu": _clean_c_string(cpu),
        "flash": _clean_c_string(flash),
        "entry_count": count,
        "project_info": _clean_c_string(project_info),
        "crc": crc,
    }

    entries = []
    for index in range(count):
        chunk = entry_data[index * ENTRY_LENGTH : (index + 1) * ENTRY_LENGTH]
        label, offset, length, encrypted_length, filename, entry_crc = unpack("<32s Q Q Q 32s Q", chunk)
        if not offset and not length:
            continue
        entries.append(
            {
                "index": index,
                "label": _clean_c_string(label),
                "offset": offset,
                "length": length,
                "encrypted_length": encrypted_length,
                "filename": _clean_c_string(filename),
                "crc": entry_crc,
            }
        )
    return package, entries


def _select_key(ofp_path: Path, entries: list[dict[str, str | int]]) -> tuple[int, bytes, bytes]:
    scatter = next((entry for entry in entries if entry["filename"] == "MT6750_Android_scatter.txt"), None)
    if scatter is None:
        raise RuntimeError("No MT6750_Android_scatter.txt entry found in OFP index.")

    with ofp_path.open("rb") as handle:
        handle.seek(int(scatter["offset"]))
        encrypted = handle.read(min(int(scatter["encrypted_length"]), 4096))

    for index, table in enumerate(KEY_TABLES):
        key, iv = _derive_key(table)
        data = _decrypt_prefix(key, iv, encrypted)
        if b"partition_index" in data and b"MT6750" in data:
            return index, key, iv

    raise RuntimeError("No known key decrypted the embedded scatter entry.")


def extract(ofp_path: Path, output_dir: Path, overwrite: bool = False) -> None:
    package, entries = _parse_entries(ofp_path)
    key_index, key, iv = _select_key(ofp_path, entries)

    output_dir.mkdir(parents=True, exist_ok=True)
    print(f"Project: {package['project']}")
    print(f"Project info: {package['project_info']}")
    print(f"Entries: {len(entries)}")
    print(f"Selected key index: {key_index}")

    with ofp_path.open("rb") as handle:
        for entry in entries:
            filename = str(entry["filename"] or f"{entry['label']}.img")
            target = output_dir / filename
            if target.exists() and not overwrite:
                target = output_dir / f"{target.stem}.{entry['label']}{target.suffix}"

            total_length = int(entry["length"])
            encrypted_length = int(entry["encrypted_length"])
            remaining = total_length - encrypted_length
            print(f"Writing {entry['label']} -> {target.name} ({total_length} bytes)")

            handle.seek(int(entry["offset"]))
            with target.open("wb") as output:
                if encrypted_length:
                    output.write(_decrypt_prefix(key, iv, handle.read(encrypted_length)))

                while remaining > 0:
                    size = min(READ_CHUNK, remaining)
                    output.write(handle.read(size))
                    remaining -= size


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract OPPO/Realme MediaTek OFP firmware.")
    parser.add_argument("ofp", type=Path, help="Path to the .ofp file")
    parser.add_argument("output", type=Path, help="Directory for extracted files")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite duplicate output names")
    args = parser.parse_args()

    extract(args.ofp, args.output, args.overwrite)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
