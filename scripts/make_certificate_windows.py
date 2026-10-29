#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
灵动时钟 —— Windows 本地准备签名材料的辅助脚本（无需 Mac / Keychain Access）。

依赖：仅 Python 标准库；OpenSSL 可由 Git for Windows 自带（命令行 openssl 可用即可）。

子命令：
  steps             打印完整操作步骤与可复制命令模板
  b64 <文件路径>    把 p12 / mobileprovision 编码为单行 base64，便于粘贴到 GitHub Secret
"""

import argparse
import base64
import pathlib
import sys


def cmd_steps(_args):
    print(__doc__)
    print("=" * 72)
    print("第 1 步：生成私钥与 CSR（在 Git Bash 或 PowerShell 中执行）")
    print("-" * 72)
    print('openssl genrsa -out private_key.pem 2048')
    print('openssl req -new -key private_key.pem -out csr.csr '
          '-subj "/CN=LiveClock Development/O=Self/C=CN"')
    print()
    print("第 2 步：浏览器打开 developer.apple.com → Account →")
    print("Certificates, Identifiers & Profiles → Certificates → 点 +")
    print("自用调试选 Apple Development；粘贴 csr.csr 全文，下载 .cer 文件。")
    print()
    print("第 3 步：把 DER 格式 .cer 转 PEM，再打包为 macOS 可识别的 legacy p12")
    print("-" * 72)
    print('openssl x509 -inform DER -in ios_development.cer -out cert.pem')
    print('openssl pkcs12 -export -legacy -inkey private_key.pem -in cert.pem '
          '-name "LiveClock Dev" -out dist.p12 -passout pass:换成你的p12密码')
    print()
    print("第 4 步：生成 GitHub Secret 所需的单行 base64")
    print("-" * 72)
    print('python make_certificate_windows.py b64 dist.p12')
    print()
    print("第 5 步：在 Identifiers 注册两个 App ID 与一个 App Group；")
    print("在 Profiles 分别为主 App / Widget 创建 Apple Development 描述文件并下载，")
    print("同样用 b64 命令编码后存入 Secret（APP_PROFILE_BASE64 / WIDGET_PROFILE_BASE64）。")


def cmd_b64(args):
    path = pathlib.Path(args.file)
    if not path.exists():
        print(f"文件不存在: {path}", file=sys.stderr)
        sys.exit(1)
    encoded = base64.b64encode(path.read_bytes()).decode()
    out = pathlib.Path(str(path) + ".b64")
    out.write_text(encoded)
    print(encoded)
    print(f"\n已写入: {out}（单行文本，可直接粘贴到 GitHub Secret）")


def main():
    parser = argparse.ArgumentParser(description="iOS 签名材料辅助脚本（Windows 无 Mac 场景）")
    sub = parser.add_subparsers(dest="command", required=True)

    sp = sub.add_parser("steps", help="打印操作步骤与命令模板")
    sp.set_defaults(func=cmd_steps)

    bp = sub.add_parser("b64", help="文件编码为单行 base64")
    bp.add_argument("file", help="待编码文件路径，如 dist.p12")
    bp.set_defaults(func=cmd_b64)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
