From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 24 Dec 2024 13:42:37 +0100
Subject: [PATCH] scripts/make_fit: Print DT name before libfdt errors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241224-makefit-v1-1-feeccef137ee@posteo.net>
X-B4-Tracking: v=1; b=H4sIADysamcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDIyMT3dzE7NS0zBJdY8M0cwvLJMvUVJM0JaDqgiKgcAXYpOjY2loA/1A
 rUlkAAAA=
X-Change-ID: 20241224-makefit-31f789b9ee4f
To: Simon Glass <sjg@chromium.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735044177; l=2504;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=qNYHUnAZnyBHAWNkYsjAlxvZcMVlVw3UbvcsQUL+fy8=;
 b=9cH15+82rUPew5FWYHisRJZ1579YkP0KJq670oUqZwkqMpTzQQZuQusGEXLCKZFJwse0LY8dZ
 hkbIfmJtBr/CsITqhiVUYuXQ0IpgidL4z/7RTB2Pxlpmhz0qmFvof0P
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This makes it easier to pinpoint where the error happened. For example:

  FIT     arch/powerpc/boot/image.fit
Error processing arch/powerpc/boot/dts/microwatt.dtb:
Traceback (most recent call last):
  File "/home/jn/dev/linux/linux-git/build-mpc83xx/../scripts/make_fit.py", line 335, in <module>
    sys.exit(run_make_fit())
             ^^^^^^^^^^^^^^
  File "/home/jn/dev/linux/linux-git/build-mpc83xx/../scripts/make_fit.py", line 309, in run_make_fit
    out_data, count, size = build_fit(args)
                            ^^^^^^^^^^^^^^^
  File "/home/jn/dev/linux/linux-git/build-mpc83xx/../scripts/make_fit.py", line 286, in build_fit
    raise e
  File "/home/jn/dev/linux/linux-git/build-mpc83xx/../scripts/make_fit.py", line 283, in build_fit
    (model, compat, files) = process_dtb(fname, args)
                             ^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/jn/dev/linux/linux-git/build-mpc83xx/../scripts/make_fit.py", line 231, in process_dtb
    model = fdt.getprop(0, 'model').as_str()
            ^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3/dist-packages/libfdt.py", line 448, in getprop
    pdata = check_err_null(fdt_getprop(self._fdt, nodeoffset, prop_name),
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3/dist-packages/libfdt.py", line 153, in check_err_null
    raise FdtException(val)
libfdt.FdtException: pylibfdt error -1: FDT_ERR_NOTFOUND

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
The example is from a different series which I will release soon, which
enables FIT on powerpc.
---
 scripts/make_fit.py | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/scripts/make_fit.py b/scripts/make_fit.py
index 4a1bb2f55861adfce07959528e175260bc503593..1683e5ec6e6754dff3383dfec89df78b9c2fa896 100755
--- a/scripts/make_fit.py
+++ b/scripts/make_fit.py
@@ -279,7 +279,11 @@ def build_fit(args):
         if os.path.splitext(fname)[1] != '.dtb':
             continue
 
-        (model, compat, files) = process_dtb(fname, args)
+        try:
+            (model, compat, files) = process_dtb(fname, args)
+        except Exception as e:
+            sys.stderr.write(f"Error processing {fname}:\n")
+            raise e
 
         for fn in files:
             if fn not in fdts:

---
base-commit: 4bbf9020becbfd8fc2c3da790855b7042fad455b
change-id: 20241224-makefit-31f789b9ee4f

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

