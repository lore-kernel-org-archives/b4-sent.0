From: Louis Rannou <louis.rannou@non.se.com>
Date: Mon, 11 May 2026 13:47:23 +0200
Subject: [PATCH v2] openvpn: create an extra package for the dns-updown
 script
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-bash-rr-v2-1-63833caf12aa@non.se.com>
X-B4-Tracking: v=1; b=H4sIAMrBAWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIzMDUwMz3aTE4gzdoiJd07QUAwsjA1NDy1QTJaDqgqLUtMwKsEnRsbW1AIz
 q2iVZAAAA
To: openembedded-devel@lists.openembedded.org
Cc: pascal.eberhard@non.se.com, Louis Rannou <louis.rannou@non.se.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778500045; l=1832;
 i=louis.rannou@non.se.com; s=20250630; h=from:subject:message-id;
 bh=Ak15XMMxbMKcTUukb9UZ6uXAq9ojZ6Vpr1NDZ+t4Frg=;
 b=OPr5cmufiFAydWmMOnef4SPjGdF+ciFlw8Rb8ZazgiMNiuW1Q3/QLvY/mBn4aXs+viVWqkKM6
 I5pH4mX0ke6AaByRrHwK98DTXJcBUkZRx7hRpjht4Nb1ctwxVRYAKul
X-Developer-Key: i=louis.rannou@non.se.com; a=ed25519;
 pk=WWYN5/DFKqyCKdv6oTYNuq0gROqwZVfNfw2OMI3tUlc=
X-Endpoint-Received: by B4 Relay for louis.rannou@non.se.com/20250630 with auth_id=446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dns-updown script is written in bash which is under the GPLv3
license. As this script is optional, it is preffered to have it in an extra
package.

Signed-off-by: Louis Rannou <louis.rannou@non.se.com>
---
change in v2: new package openvpn-dns-updown
---
 meta-networking/recipes-support/openvpn/openvpn_2.7.0.bb | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/meta-networking/recipes-support/openvpn/openvpn_2.7.0.bb b/meta-networking/recipes-support/openvpn/openvpn_2.7.0.bb
index 0cbe4641cd..6ddebde4d1 100644
--- a/meta-networking/recipes-support/openvpn/openvpn_2.7.0.bb
+++ b/meta-networking/recipes-support/openvpn/openvpn_2.7.0.bb
@@ -47,7 +47,7 @@ PACKAGECONFIG[iproute2] = "--enable-iproute2,,iproute2,iproute2-ip"
 PACKAGECONFIG[systemd] = "--enable-systemd,--disable-systemd,systemd"
 PACKAGECONFIG[selinux] = "--enable-selinux,--disable-selinux,libselinux"
 
-RDEPENDS:${PN}:append = " bash"
+RDEPENDS:${PN}-dns-updown:append = " bash"
 RDEPENDS:${PN}-ptest:append = " bash"
 
 do_install:append() {
@@ -114,7 +114,7 @@ do_install_ptest() {
     cp -f ${S}/tests/t_lpback.sh ${D}/${PTEST_PATH}
 }
 
-PACKAGES =+ " ${PN}-sample "
+PACKAGES =+ " ${PN}-dns-updown ${PN}-sample "
 
 RRECOMMENDS:${PN} = "kernel-module-tun"
 
@@ -124,5 +124,6 @@ FILES:${PN} += "${systemd_system_unitdir}/openvpn-server@.service \
                 ${systemd_system_unitdir}/openvpn-client@.service \
                 ${nonarch_libdir}/tmpfiles.d \
                "
+FILES:${PN}-dns-updown = "${libexecdir}/openvpn/dns-updown"
 FILES:${PN}-sample = "${sysconfdir}/openvpn/sample/ \
                      "

---
base-commit: 420222862f5a6d95023b8f5f3b7e1808b2264ef9
change-id: 20260506-bash-rr-5fd0820519e4

Best regards,
-- 
Louis Rannou <louis.rannou@non.se.com>

