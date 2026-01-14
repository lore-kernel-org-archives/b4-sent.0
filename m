From: Jihan LIN <linjh22s@gmail.com>
Date: Wed, 14 Jan 2026 19:47:44 +0800
Subject: [PATCH v2 1/2] Documentation/kbuild: Document gendwarfksyms build
 dependencies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260114-documents_gendwarfksyms-v2-1-297c98bd62c6@gmail.com>
References: <20260114-documents_gendwarfksyms-v2-0-297c98bd62c6@gmail.com>
In-Reply-To: <20260114-documents_gendwarfksyms-v2-0-297c98bd62c6@gmail.com>
To: Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun.feng@gmail.com>, Sami Tolvanen <samitolvanen@google.com>, 
 Masahiro Yamada <masahiroy@kernel.org>, Petr Pavlu <petr.pavlu@suse.com>
Cc: linux-modules@vger.kernel.org, linux-kbuild@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jihan LIN <linjh22s@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768391298; l=1690;
 i=linjh22s@gmail.com; s=linjh22s_machine; h=from:subject:message-id;
 bh=zaWdvli633/VK3S2KUL14PgYlfdPOQbClm+Z3p3BhUE=;
 b=kMzqRJLPJqr33VLRjq0RPNsdmz0bA0nnzM52+b1Yznalz4e6Xi+T+3tx9pdylN9m4W96yQ43T
 LXR12zdX+BGC5BlQJHChFfDCzW/e24NiHXQ2OmYFX8auZna93/Zztkr
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
Signed-off-by: Jihan LIN <linjh22s@gmail.com>
---
 Documentation/kbuild/gendwarfksyms.rst | 23 +++++++++++++++++++++++
 1 file changed, 23 insertions(+)

diff --git a/Documentation/kbuild/gendwarfksyms.rst b/Documentation/kbuild/gendwarfksyms.rst
index ed366250a54eac3a72c2f529da94a9e803704ae4..0e153d13b052da6edcf65950739730c123cd49db 100644
--- a/Documentation/kbuild/gendwarfksyms.rst
+++ b/Documentation/kbuild/gendwarfksyms.rst
@@ -14,6 +14,29 @@ selected, **gendwarfksyms** is used instead to calculate symbol versions
 from the DWARF debugging information, which contains the necessary
 details about the final module ABI.
 
+Dependencies
+------------
+
+libelf, libdw and zlib are dependencies of gendwarfksyms.
+
+Here are a few examples for installing these dependencies:
+
+* Arch Linux and derivatives::
+
+	sudo pacman --needed -S zlib libelf
+
+* Debian, Ubuntu, and derivatives::
+
+	sudo apt install libelf-dev libdw-dev zlib1g-dev
+
+* Fedora and derivatives::
+
+	sudo dnf install elfutils-libelf-devel elfutils-devel zlib-devel
+
+* openSUSE and derivatives::
+
+	sudo zypper install libelf-devel libdw-devel zlib-devel
+
 Usage
 -----
 

-- 
2.51.0

