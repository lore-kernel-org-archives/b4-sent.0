From: Daniel Gomez <da.gomez@samsung.com>
Date: Fri, 06 Sep 2024 13:01:35 +0200
Subject: [PATCH v2 8/8] Documentation: add howto build in macos
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240906-macos-build-support-v2-8-06beff418848@samsung.com>
References: <20240906-macos-build-support-v2-0-06beff418848@samsung.com>
In-Reply-To: <20240906-macos-build-support-v2-0-06beff418848@samsung.com>
To: Masahiro Yamada <masahiroy@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nicolas@fjasle.eu>, 
 Lucas De Marchi <lucas.demarchi@intel.com>, 
 =?utf-8?q?Thomas_Hellstr=C3=B6m?= <thomas.hellstrom@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, William Hubbs <w.d.hubbs@gmail.com>, 
 Chris Brannon <chris@the-brannons.com>, Kirk Reiser <kirk@reisers.ca>, 
 Samuel Thibault <samuel.thibault@ens-lyon.org>, 
 Paul Moore <paul@paul-moore.com>, 
 Stephen Smalley <stephen.smalley.work@gmail.com>, 
 Ondrej Mosnacek <omosnace@redhat.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Marc Zyngier <maz@kernel.org>, Oliver Upton <oliver.upton@linux.dev>, 
 James Morse <james.morse@arm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>, 
 Simona Vetter <simona.vetter@ffwll.ch>
Cc: linux-kernel@vger.kernel.org, linux-kbuild@vger.kernel.org, 
 intel-xe@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 speakup@linux-speakup.org, selinux@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, kvmarm@lists.linux.dev, 
 linux-serial@vger.kernel.org, llvm@lists.linux.dev, 
 Finn Behrens <me@kloenk.dev>, 
 "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725620498; l=3295;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=d0Jf83ehBVzZd/6sDJAXa3klyzghUuKXMDUak+RyqVk=;
 b=HHVXUAKYpwg0oAq4Llj7Qicr7YTY8yOi8z/Ymdnnl/W0ykKZJbrrJ5EOU8LrjlVkcwlA+JR2O
 50rFNWri/6gCAgythyvckdtJX73zV3YaMq3ZWFUY7eZPAc4+9wznTjX
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation under kbuild/llvm to inform about the experimental
support for building the Linux kernel in macOS hosts environments.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 Documentation/kbuild/llvm.rst | 78 +++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 78 insertions(+)

diff --git a/Documentation/kbuild/llvm.rst b/Documentation/kbuild/llvm.rst
index 6dc66b4f31a7..de3bde925793 100644
--- a/Documentation/kbuild/llvm.rst
+++ b/Documentation/kbuild/llvm.rst
@@ -186,6 +186,84 @@ yet. Bug reports are always welcome at the issue tracker below!
      - Supported
      - ``LLVM=1``
 
+Experimental Build in macOS
+---------------------------
+
+Building on macOS with LLVM is experimental. This section provides steps to
+install dependencies via Homebrew, set up the environment, and start the build
+process.
+
+1. **Create a Case-Sensitive Volume**
+
+   For fetching and building the project, you need a case-sensitive volume. Use the following
+   command to create one:
+
+   .. code-block:: shell
+
+      diskutil apfs addVolume /dev/disk<N> "Case-sensitive APFS" linux
+
+   Replace `/dev/disk<N>` with the appropriate disk identifier.
+
+2. **Install Build Dependencies**
+
+Use Homebrew to install the required build dependencies.
+
+- **Core Utilities**: `coreutils`, `findutils`, `gnu-sed`, `gnu-tar`, `grep`,
+  `llvm`, `make`, and `pkg-config`.
+
+   .. code-block:: shell
+
+      brew install coreutils findutils gnu-sed gnu-tar grep llvm make pkg-config
+
+- **Bee Headers**: Install byteswap, elf and endian headers using the
+  `Bee Headers Project <https://github.com/bee-headers/headers>`_.
+
+   .. code-block:: shell
+
+      brew tap bee-headers/bee-headers
+      brew install bee-headers/bee-headers/bee-headers
+
+   After installation, verify the `CFLAGS` with `pkg-config`:
+
+   .. code-block:: shell
+
+      pkg-config --cflags bee-headers
+      -I/opt/homebrew/Cellar/bee-headers/0.1/include
+
+3. **Configure the PATH**
+
+   Include all the required GNU tools and LLVM in your `PATH`. This ensures that
+   the necessary tools are available during the build process.
+
+   .. code-block:: shell
+
+      PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
+      PATH="/opt/homebrew/opt/findutils/libexec/gnubin:$PATH"
+      PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
+      PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"
+      PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
+      PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"
+      PATH="/opt/homebrew/opt/llvm/bin:$PATH"
+
+Building the Project
+--------------------
+
+Once the environment is set up, you can start the build process using LLVM. Run
+the following commands to initiate the build:
+
+.. code-block:: shell
+
+   make LLVM=1 allyesconfig
+   make LLVM=1 -j$(nproc)
+
+Supported in macOS
+~~~~~~~~~~~~~~~~~~
+
+At the moment, only arm64 is supported and tested with `allyesconfig` Makefile
+configuration target. Other Kconfig options not included in `allyesconfig`
+target and architectures may be supported as well as support in macOS is based
+on LLVM effort and maintenance.
+
 Getting Help
 ------------
 

-- 
2.46.0

