From: Massimiliano Minella <massimiliano.minella@se.com>
Date: Tue, 21 Jan 2025 16:12:47 +0100
Subject: [PATCH RESEND meta-virtualization] virt-manager: use inherit_defer
 for optional gtk-icon-cache class
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250121-use_inherit_defer-v1-1-dbfd42de3a01@se.com>
To: meta-virtualization@lists.yoctoproject.org
Cc: Massimiliano Minella <massimiliano.minella@se.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737472369; l=1359;
 i=massimiliano.minella@se.com; s=20250121; h=from:subject:message-id;
 bh=zh1M+VIYhaVDdHzTqvyHbs1bN9I+xLH2CnDVhSv29bw=;
 b=aXlIka1l/NgkiYWrC9Kfx8FUuiIFOShokd0dQdhOWw1IusYkflCNmgiy1T+tApnicGkBVQfvD
 vISmO1GX0bED2HcwRvCoAvdvqAZALElxfw28CovjtQjcaNgNVoVqm4t
X-Developer-Key: i=massimiliano.minella@se.com; a=ed25519;
 pk=p6Og4stDBPm4cBEySH8oVWARLO52pxVayNFqHslSXU0=
X-Endpoint-Received: by B4 Relay for massimiliano.minella@se.com/20250121 with auth_id=325
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The inherit is controlled by the PACKAGECONFIG option "gui" but, since
it is expanded at parse time, this causes a build error if the option is
removed via a bbappend and DISTRO_FEATURES doesn't contain "x11" or
"wayland". Replace the inherit with inherit_defer to evaluate the
inherit at the end of parsing.

Signed-off-by: Massimiliano Minella <massimiliano.minella@se.com>
---
 recipes-extended/virt-manager/virt-manager_4.1.0.bb | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git recipes-extended/virt-manager/virt-manager_4.1.0.bb recipes-extended/virt-manager/virt-manager_4.1.0.bb
index d752fd2b..08b7d02b 100644
--- recipes-extended/virt-manager/virt-manager_4.1.0.bb
+++ recipes-extended/virt-manager/virt-manager_4.1.0.bb
@@ -15,7 +15,7 @@ S = "${WORKDIR}/git"
 PACKAGECONFIG ??= "gui"
 PACKAGECONFIG[gui] = ",--no-update-icon-cache --no-compile-schemas,python3-pygobject"
 
-inherit ${@bb.utils.contains('PACKAGECONFIG', 'gui', 'gtk-icon-cache', '', d)}
+inherit_defer ${@bb.utils.contains('PACKAGECONFIG', 'gui', 'gtk-icon-cache', '', d)}
 inherit bash-completion gettext pkgconfig setuptools3_legacy
 
 PACKAGES += " \

---
base-commit: b57f8a25a35a93b95e3baa950c2d359fffc13051
change-id: 20250121-use_inherit_defer-0d8e1fb85c13

Best regards,
-- 
Massimiliano Minella <massimiliano.minella@se.com>

