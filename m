From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 18 Dec 2024 11:30:06 +0100
Subject: [PATCH 12/12] ansible: Set running_user explicitly to the USER var
 of the script
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241218-jag-bringup_fixes-v1-12-0bf2e07c640c@kernel.org>
References: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
In-Reply-To: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=643;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=jRfRt47UG+s1NGe9WMjH6iz6cKXD6GqKWu00bPFiEVg=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGdipDGa3SrpCmkBmvrXTdNWDCU/X+w6tW43b
 E4Uugj0ChOqlYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnYqQxAAoJELqXzVK3
 lkFPgWIL/1ctWbAdJMTzWrWqR0Vmhh6uc4qGcgUVpb6T6cDM5qjnm5tiGFek5m9edl/p/4WLlbe
 DI926Xgfep6pHW64vRqj9ZfGLD1yUniZPUPoEUaIpDxfnAd6hb4cDFdLrZgap5imX0IJ9WFkHir
 eJAm/lXU6nHKmybmNrRLiwbYZrSEHyLuuKUrVBZDfGgDsVNCGV/m7mQrUOHGNM/p6ticVnTP4j6
 mWoE8oP3tCPPDoOgLP5a0pSIeQMGzbYdziZbtx2751QQFTjc008W5XDSf0H6k+viqV/efOZRV3W
 qiuCCbW/fWDjzmi2CdrCQfsENeVXFmMlWBp9ELJDRviYRP3XvLssNqj+jGCOEwm81Pa53kcB7y4
 oMFi+RunITuyl/A26fvZQShSCo5ouFicEdfUL5k05aOjmCb/vTTWKoLpUM+nIuCjgoD/3U0Igrd
 KNCIDLOdbpXXQF02W8trGpR+36n99V4YSIiG/i8GKof8VuQrD7Rq76Otv6+0sKbiZamixiW4zQ6
 g4=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 scripts/guestfs.Makefile | 1 +
 1 file changed, 1 insertion(+)

diff --git a/scripts/guestfs.Makefile b/scripts/guestfs.Makefile
index 480bc4f..f463ecc 100644
--- a/scripts/guestfs.Makefile
+++ b/scripts/guestfs.Makefile
@@ -77,6 +77,7 @@ bringup_guestfs: $(GUESTFS_BRINGUP_DEPS)
 		--inventory localhost, \
 		playbooks/bringup_guestfs.yml \
 		-e 'ansible_python_interpreter=/usr/bin/python3' \
+		-e 'running_user=$(USER)' \
 		--extra-vars=@./extra_vars.yaml \
 		--tags config-check,network,build-deps
 	$(Q)$(TOPDIR)/scripts/bringup_guestfs.sh

-- 
2.44.2

