From: Manas <manas18244@iiitd.ac.in>
Date: Thu, 28 Nov 2024 23:31:01 +0530
Subject: [PATCH] scripts: checkpatch: add check for simplifying Result<()>
 in Rust
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241128-add-checkpatch-result-simplify-v1-1-973603191d71@iiitd.ac.in>
X-B4-Tracking: v=1; b=H4sIANyvSGcC/x3NQQqDMBBA0avIrB0wIZbUqxQXIZk0Q9WGjJaKe
 HeDy7f5/wChwiQwNAcU+rHwd6lQbQM+ueVNyKEadKeNUrpHFwL6RP6T3eoTFpJtWlF4zhPHHW2
 gaIx9dMY+oUZyocj/e/Aaz/MCOd8+qXAAAAA=
X-Change-ID: 20241125-add-checkpatch-result-simplify-8def44860489
To: Dwaipayan Ray <dwaipayanray1@gmail.com>, 
 Lukas Bulwahn <lukas.bulwahn@gmail.com>, Joe Perches <joe@perches.com>, 
 Jonathan Corbet <corbet@lwn.net>, Andy Whitcroft <apw@canonical.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>
Cc: Shuah Khan <skhan@linuxfoundation.org>, 
 Anup Sharma <anupnewsmail@gmail.com>, workflows@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, Manas <manas18244@iiitd.ac.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732816872; l=2172;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=Yhg0Ax2bzUaeocHIPB521o3yw72SKvbWMASGFnH7NM4=;
 b=7pdOmFPyTmRUpXH4SlrO2kU0eAmnIH4h6ivizmdAaUlwcZXhvpaFmQin5AAFXfxiqwxDAcvQK
 U27/BjXyUknCyY2ygzRyg/raLgXHDrGZc+SVGtL6d3jgsK4+cVnoyzR
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The type Result<()> can be rewritten simply as Result, as default type
parameters are unit `()` and `Error` types already. Thus keep usage of
`Result` consistent throughout codebase.

Suggested-by: Miguel Ojeda <ojeda@kernel.org>
Link: https://github.com/Rust-for-Linux/linux/issues/1128
Not-yet-signed-off-by: Manas <manas18244@iiitd.ac.in>
---
Note: The blockage due to my Signed-off-by tag is being resolved in
private. For now I am adding Not-yet-signed-off-by tag.
---
 Documentation/dev-tools/checkpatch.rst | 10 ++++++++++
 scripts/checkpatch.pl                  |  9 +++++++++
 2 files changed, 19 insertions(+)

diff --git a/Documentation/dev-tools/checkpatch.rst b/Documentation/dev-tools/checkpatch.rst
index abb3ff6820766ee0c29112b256bcc44ce41fffba..7bf1fc7d4d7b490b32b8863365afe12a6732d6c1 100644
--- a/Documentation/dev-tools/checkpatch.rst
+++ b/Documentation/dev-tools/checkpatch.rst
@@ -1018,6 +1018,16 @@ Functions and Variables
 
       return bar;
 
+  **SIMPLIFIED_RESULT**
+    simplifies Result<()> in Rust codebase as Result because default type
+    parameters are unit and Error types::
+
+      fn foo(x: Result<()>) -> Result<()> {}
+
+    can be rewritten as::
+
+      fn foo(x: Result) -> Result {}
+
 
 Permissions
 -----------
diff --git a/scripts/checkpatch.pl b/scripts/checkpatch.pl
index 9eed3683ad76caffbbb2418e5dbea7551d374406..ddc943fd4a62d58cee92f8723e7634af4ca69e32 100755
--- a/scripts/checkpatch.pl
+++ b/scripts/checkpatch.pl
@@ -3574,6 +3574,15 @@ sub process {
 			}
 		}
 
+# Check for Result<()> usage in Rust code
+    if ($realfile =~ /\.rs$/ &&
+        $sline =~ /^\+.*Result<\(\)>/) {
+      $check = 1;
+      if (CHK("SIMPLIFIED_RESULT", "Result<()> can be rewritten simply as Result\n" . $herecurr) && $fix) {
+        $fixed[$fixlinenr] =~ s/Result<\(\)>/Result/g;
+      }
+    }
+
 # ignore non-hunk lines and lines being removed
 		next if (!$hunk_line || $line =~ /^-/);
 

---
base-commit: 1dc707e647bc919834eff9636c8d00b78c782545
change-id: 20241125-add-checkpatch-result-simplify-8def44860489

Best regards,
-- 
Manas <manas18244@iiitd.ac.in>

