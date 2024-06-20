From: Joel Granados <j.granados@samsung.com>
Date: Thu, 20 Jun 2024 21:48:32 +0200
Subject: [PATCH] kbuild: scripts/gdb: bring the "abspath" back
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240620-jag-fix_gdb_py_symlinks-v1-1-36a0f0217fbf@samsung.com>
X-B4-Tracking: v=1; b=H4sIAI+HdGYC/x2M0QqDMAwAf0XyvEINU5m/MkapJtZM7aSBoYj/b
 vHx4O4OUE7CCm1xQOK/qPxihvJRQD/6GNgIZQa0+LQ1WvP1wQyyuUCdW3en+zJLnNRgSS+yxE3
 lEXK9Js7afX5/zvMCD8QIh2kAAAA=
To: Jan Kiszka <jan.kiszka@siemens.com>, 
 Kieran Bingham <kbingham@kernel.org>, 
 Masahiro Yamada <masahiroy@kernel.org>, 
 Douglas Anderson <dianders@chromium.org>
Cc: linux-kernel@vger.kernel.org, Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1168;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=7bxRLJCekPbUSVVSEsWXoyZjnOy26Cg5VuTjO3pr+oE=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGZ0h57LponIbCQBtuQrDWoo00muw2dl46UfY
 lbQoIiRBEF2cYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmdIeeAAoJELqXzVK3
 lkFPNXsL+QH5ec584sP4USYWj0gOobplkUCoahv1IEkdH+Ickt99MPv4hjWhWf15yQ0FS2tlHsu
 C8d04+dFpneDHgf0QA5gdxYkNeeLGspljAX+RqwHeocx/Emvp+/v1/BxPELQkpWfcaWBjxyqt2z
 EmCdqTnRONrblxq0rZnEA9g+qDtwomMV5S16AULcNUG2H8Kb52fJNBauR2ddmRDDz8Lz7HjPWOQ
 mlGFCLoQaPkmMW+zBxvoa1pZ8YRMO9jqxMTchqFwML+7vWOa6Ffa0HjCpS0SA5Uw4J6O95/KbQ2
 wA1JYegCO7FlomsJKErRe2uxhr0KH080xk2AhC3syyMh8mZYOGu03MkB1SUTHZ7QxoBh49JJD1c
 YqISa7rhlaron+Vexeyxe5/XDqqhi+Lm1R6Yraf7qYY3zLUxiOqDnDdn7S49pRBsNfDmChwsmuZ
 Qdi7aXNBLXepGGdU6ltmLObwZhayozdQh+3xkmFJljYqxJmYu6nJHX4d5RamJQ2nftZQUYjFEg5
 rA=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the "abspath" call when symlinking the gdb python scripts in
scripts/gdb/linux. This call is needed to avoid broken links when
running the scripts_gdb target on a different build directory
(O=builddir).

Fixes: 659bbf7e1b08 ("kbuild: scripts/gdb: Replace missed $(srctree)/$(src) w/ $(src)")
Signed-off-by: Joel Granados <j.granados@samsung.com>
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

