From: Massimiliano Minella <massimiliano.minella@se.com>
Date: Wed, 07 Jan 2026 17:33:59 +0100
Subject: [PATCH] libvirt: fix python3 compatibility in hook_support.py
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260107-fix_libvirt_hook_script-v1-1-d0016e043ca4@se.com>
X-B4-Tracking: v=1; b=H4sIAPaKXmkC/x2MWwqAMAzAriL9dtBNfF5FZOisWhQnnYgg3t3hZ
 yDJA4GEKUCTPCB0cWC/R9BpAm7p95kUj5HBoClQY6kmvu3Gw8Vy2sX71QYnfJzKZZrq3GCFVEO
 sD6Go/ue2e98PPExUN2kAAAA=
To: meta-virtualization@lists.yoctoproject.org
Cc: Massimiliano Minella <massimiliano.minella@se.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767803643; l=1846;
 i=massimiliano.minella@se.com; s=20250121; h=from:subject:message-id;
 bh=rROvFh/A5TUsfDeJYorMQKChOPNCM3z8U5Y7jgBNGDA=;
 b=MUnCT8xzbPoxIhkE3+A6mgJTDMwkckek6DkIxKUl1B6yZpMkgKafV7/s3WvU9UOp5PuIr73na
 rO1A6PAYhYXDqhCI5pJ6k+xV1LTgsLK9tNlDTc6nW31Ew0umkTc0OFf
X-Developer-Key: i=massimiliano.minella@se.com; a=ed25519;
 pk=p6Og4stDBPm4cBEySH8oVWARLO52pxVayNFqHslSXU0=
X-Endpoint-Received: by B4 Relay for massimiliano.minella@se.com/20250121 with auth_id=325
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

By default Popen expects all the streams to be bytes-like objects but,
in the Popen.communicate() function call, the "input" argument is a
string, making the call fail with the error:

qemu hook error: a bytes-like object is required, not 'str'

Fix the error by setting text mode to True in the subprocess creation.

Also fix the "SyntaxWarning: invalid escape sequence '\w'" in the regex
used to match script names.

Signed-off-by: Massimiliano Minella <massimiliano.minella@se.com>
---
 recipes-extended/libvirt/libvirt/hook_support.py | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git recipes-extended/libvirt/libvirt/hook_support.py recipes-extended/libvirt/libvirt/hook_support.py
index 7c5e2a94..63e78b79 100755
--- recipes-extended/libvirt/libvirt/hook_support.py
+++ recipes-extended/libvirt/libvirt/hook_support.py
@@ -35,7 +35,7 @@ def main():
 			stdin_save = sys.stdin.readlines()
 		# Match the name name of the hook + a dash + atleast
 		# one alpha-numeric character.
-		matcher = re.compile( "%s-\w+" % hook_name )
+		matcher = re.compile( rf"%s-\w+" % hook_name )
 		for file_name in sorted( os.listdir( hook_dir ) ):
 			file_path = os.path.join( hook_dir, file_name )
 			if matcher.match( file_name ) \
@@ -43,7 +43,7 @@ def main():
 			   and os.path.isfile( file_path ) \
 			   and return_value == 0:
 				cmd = [ file_path ] + hook_args
-				p = subprocess.Popen( cmd, stdin=subprocess.PIPE )
+				p = subprocess.Popen( cmd, stdin=subprocess.PIPE, text=True )
 				p.communicate( input = ''.join( stdin_save ) )[0]
 				return_value = p.wait()
 	except Exception as e:

---
base-commit: 28d26fd95397bf575e65fcca0cbb302b1e9bc7ff
change-id: 20260107-fix_libvirt_hook_script-c31e952080e9

Best regards,
-- 
Massimiliano Minella <massimiliano.minella@se.com>

