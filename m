From: Joel Granados <j.granados@samsung.com>
Date: Wed, 26 Jun 2024 14:06:16 +0200
Subject: [PATCH v2] kbuild: scripts/gdb: bring the "abspath" back
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240626-jag-fix_gdb_py_symlinks-v2-1-1a05406c8063@samsung.com>
X-B4-Tracking: v=1; b=H4sIADcEfGYC/4WNXQ6CMBCEr0L22Zp2VYg+eQ9DSKE/rNpCukokh
 LtbuYCP32TmmwXYJrIMl2KBZCdiGmIG3BXQ9Tp6K8hkBpR4lCVKcddeOPo03rTNODc8hyfFBwt
 U5myksdVJI+T1mGyubeZbnbknfg1p3o4m9Uv/OycllDiUWjqJqnKtu7IO/I5+3w0B6nVdv7Wnw
 dnAAAAA
To: Jan Kiszka <jan.kiszka@siemens.com>, 
 Kieran Bingham <kbingham@kernel.org>, 
 Masahiro Yamada <masahiroy@kernel.org>, 
 Douglas Anderson <dianders@chromium.org>
Cc: linux-kernel@vger.kernel.org, Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1389;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=ELA3O2VefITuAlFWSunBt6d4ILv4gEPSDCYoeDsUf/w=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGZ8BEZ7361AGuuL1AzQ/hAcHZJ4bCyhOod8M
 AJJ0PxwNRIyY4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmfARGAAoJELqXzVK3
 lkFPbMoL/1UPGDA+dGpVQ4m8RzzzYa06hQnsp4OoNOVHK0R5EUVb0sZitdVbGD3TzLBcvKVPf51
 Ov0nMnZJ48icshqAXD6gOhd1KPJiMFJMBEtvx7QLUfa/4Hg6fhZC6XOtNwUgLO5iLdmc1MP2It7
 Uif0r7/c+MLSEUO1YtW8vUOA9jI4CiaPHD59RlcLPe2dPW/W0Ne7ODSFKD8tFLjK53pHavt9X0/
 qa0AFZZV/IKdl0zg+TWc3ZRKCXiPD7KlD2grhLbSdlcS74G3z+kiDk8KDwbR77xBAMjNNKnxMm8
 I8Ff4Mf+epcgueu71td/Jr/5QMmpEw7wYGXPWFMJbFjCSJhHTcFN7oR36zkROHPCE8dtEDS6lGa
 oOw1AzU7sEhetdDAJaz8AftBm6KRM/TopvO4beNPZF1+lbEJ/X6piysWETAIVOQYFECBDRvKPy6
 eRcMlZWYDyBODOOPFvNDRuiR3Dgav6rX9JY2oAmLHqa0ecLrnDCwNpFN3XmsdKRwzUsPlD/X3U4
 iI=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the "abspath" call when symlinking the gdb python scripts in
scripts/gdb/linux. This call is needed to avoid broken links when
running the scripts_gdb target on a build directory located directly
under the source tree (e.g., O=builddir).

Fixes: 659bbf7e1b08 ("kbuild: scripts/gdb: Replace missed $(srctree)/$(src) w/ $(src)")
Signed-off-by: Joel Granados <j.granados@samsung.com>
---
Changes in v2:
- Rephrased the commit message to clarify what is happening
- Link to v1: https://lore.kernel.org/r/20240620-jag-fix_gdb_py_symlinks-v1-1-36a0f0217fbf@samsung.com
---
 scripts/gdb/linux/Makefile | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/scripts/gdb/linux/Makefile b/scripts/gdb/linux/Makefile
index fd1402c0a1a1..fcd32fcf3ae0 100644
--- a/scripts/gdb/linux/Makefile
+++ b/scripts/gdb/linux/Makefile
@@ -5,7 +5,7 @@ ifdef building_out_of_srctree
 symlinks := $(patsubst $(src)/%,%,$(wildcard $(src)/*.py))
 
 quiet_cmd_symlink = SYMLINK $@
-      cmd_symlink = ln -fsn $(patsubst $(obj)/%,$(src)/%,$@) $@
+      cmd_symlink = ln -fsn $(patsubst $(obj)/%,$(abspath $(src))/%,$@) $@
 
 always-y += $(symlinks)
 $(addprefix $(obj)/, $(symlinks)): FORCE

---
base-commit: 6ba59ff4227927d3a8530fc2973b80e94b54d58f
change-id: 20240620-jag-fix_gdb_py_symlinks-21d9d0de75a2

Best regards,
-- 
Joel Granados <j.granados@samsung.com>

