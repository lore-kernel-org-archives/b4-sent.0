From: Jihan LIN <linjh22s@gmail.com>
Date: Thu, 08 Jan 2026 08:44:38 +0000
Subject: [PATCH] Documentation/kbuild: Document gendwarfksyms build
 dependencies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260108-documents_gendwarfksyms-v1-1-52b1f9c38c70@gmail.com>
X-B4-Tracking: v=1; b=H4sIAHVuX2kC/x3MSQqAMAxA0atI1hZqcb6KiBSbahCrNI6Id7e4f
 Iv/H2D0hAx19IDHg5gWF5DEEfSjdgMKMsGgpMplIjNhln6f0W3cDejMqb2d+J5ZVLYsMdWFNsp
 CqFePlq7/3LTv+wEPGta9aQAAAA==
X-Change-ID: 20260105-documents_gendwarfksyms-9f88e4a7ad2f
To: Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun.feng@gmail.com>, Sami Tolvanen <samitolvanen@google.com>, 
 Masahiro Yamada <masahiroy@kernel.org>, Petr Pavlu <petr.pavlu@suse.com>
Cc: linux-kbuild@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jihan LIN <linjh22s@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767861915; l=2399;
 i=linjh22s@gmail.com; s=linjh22s_machine; h=from:subject:message-id;
 bh=Hr5ycYw2D6CoeYfL5AHxIhIwbrD9nhbsUBykKkGZxFo=;
 b=Qf7URpG3jkcQR7ZRLUMeJndMh+UWQzdYp1YASq18oNDU3mjDFAp9LQQBmrRBn6B5qKFKolmIL
 +SEjVVEX68NCLRcco4z613r1iPXqRGYH03iLsILewSqwGXTGncMdoZg
X-Developer-Key: i=linjh22s@gmail.com; a=ed25519;
 pk=MnRQAVFy1t4tiGb8ce7ohJwrN2YFXd+dA7XmzR6GmUc=
X-Endpoint-Received: by B4 Relay for linjh22s@gmail.com/linjh22s_machine with auth_id=592
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Although dependencies for gendwarfksyms were recently added to the
packaging rules [1-2], the corresponding documentation was missing.

Document the required build dependencies for gendwarfksyms, and
include a few examples for installing these dependencies on some
distributions.

[1] commit 657f96cb7c06 ("kbuild: deb-pkg: Add libdw-dev:native to
Build-Depends-Arch")
[2] commit 5bd6bdd0f76e ("kbuild: rpm-pkg: Add (elfutils-devel or
libdw-devel) to BuildRequires")

Fixes: f28568841ae0 ("tools: Add gendwarfksyms")
Signed-off-by: Jihan LIN <linjh22s@gmail.com>
---
Hi,

I found there is no documentation for build dependencies in gendwarfksyms
while digging into Rust drivers. Though Yuli added libdw-dev to the build
dependencies for packaging [1], it seems that there is no documentation
about it.

This patch documents the build dependencies of gendwarfksyms and adds a few
examples for installing these dependencies on some distributions.

[1]: https://lore.kernel.org/all/79C925DCE2E963FF+20250422104927.144252-1-wangyuli@uniontech.com/
---
 Documentation/kbuild/gendwarfksyms.rst | 23 +++++++++++++++++++++++
 1 file changed, 23 insertions(+)

diff --git a/Documentation/kbuild/gendwarfksyms.rst b/Documentation/kbuild/gendwarfksyms.rst
index ed366250a54eac3a72c2f529da94a9e803704ae4..85fe9086beb760500250e7539058dce515681378 100644
--- a/Documentation/kbuild/gendwarfksyms.rst
+++ b/Documentation/kbuild/gendwarfksyms.rst
@@ -14,6 +14,29 @@ selected, **gendwarfksyms** is used instead to calculate symbol versions
 from the DWARF debugging information, which contains the necessary
 details about the final module ABI.
 
+Dependencies
+-----
+
+libelf, libdw and zlib are dependencies of gendwarfksyms.
+
+Here are a few examples for installing these dependencies:
+
+* Arch Linux and derivatives::
+
+    sudo pacman --needed -S zlib libelf
+
+* Debian, Ubuntu, and derivatives::
+
+    sudo apt install libelf-dev libdw-dev zlib1g-dev
+
+* Fedora and derivatives::
+
+    sudo dnf install elfutils-libelf-devel elfutils-devel zlib-devel
+
+* openSUSE and derivatives::
+
+    sudo zypper install libelf-devel libdw-devel zlib-devel
+
 Usage
 -----
 

---
base-commit: f0b9d8eb98dfee8d00419aa07543bdc2c1a44fb1
change-id: 20260105-documents_gendwarfksyms-9f88e4a7ad2f

Best regards,
-- 
Jihan LIN <linjh22s@gmail.com>

