From: David Heidelberg <david@ixit.cz>
Date: Thu, 16 Oct 2025 17:10:50 +0200
Subject: [PATCH RESEND v3] ARM: multi_v7_defconfig add /proc/config.gz
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251016-arm-config_gz-v3-1-3874adbf07ad@ixit.cz>
To: Russell King <linux@armlinux.org.uk>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1307; i=david@ixit.cz;
 h=from:subject:message-id; bh=7w/aD3shZMm8S2nIaaI4q8HkXYxgH0I/7K7GWxdOw78=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo8QsAL6yf9pjJS3iO30WWOBjT6+PwMNJHZhFwG
 qnooKwCd8SJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPELAAAKCRBgAj/E00kg
 csuTEACboB0BZzXR0uwri8Qb1JkyA8RYDzGFFe4g9Hrf2EFiCVtOdkvzmo/H5wnnUvXkSKVyNYA
 jwIMrQRxPDciNoL1AaIqVN2K97isMpKKR2koVJVaWHkhBQiWqQxynMVBHsmjUE0R/mssFizOfa8
 B5Bi9ILpz9GYlM80tgC3/Tbkx75CgYHbYj4dXfSO+qB2jd5OYX63asmXQwlszi9AkSGj/SKpf7Z
 t8Vqri322w29wCdzDnDFDoHWqfNO07mR4zfibE0zX2RhKzNvvLwPBq0gSk8r1KUL680F0L9pexx
 rTlwFOR01b65TFxLfHJP1awvFBnzZ1JZPi2EEzZXUvillNszbJ9yTTIOsNjp2Pfq+rUWk4kDeAX
 FJ9mYE+ufWvHlR2erSE4V8u+8EP4wRpMhU45KVS0lXmcjtxpQDYkIz5/78rupQrLii1tcqNhppw
 yOuXkR3Xuw2Et2qyyxsLWPwj8IEzRXxXS5+1DZKcYMdn0YfO+drS7gxik8YfB1lXudeFAJi4fyU
 I+BJ+0EvDuz7nfz//pTCiiHR7EewLZmEmCLIuy5RS0Bpv4eAS2PhhjjWFQQL5c8unEIc/vy8/3u
 2ZwpUhBfOmhtd5BS+SgwKhSgPYjVGAv1GbZ3Ms/LwlyHJuOqlj59BYvT77GtmfMVJSvnyh470Jb
 cHsrH31gU1Y/LWw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While 32-bit ARM isn't that widespread, multi_v7_defconfig is used for
building more generic images, where having access to config can be handy.

arm64 and x86_64 already bundle config.gz, so this is an effort to provide
the same level of comfort with ARMv7 devices.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Rebased against next-20250715; otherwise, just a resend.
- Link to v2: https://lore.kernel.org/r/20250329-arm-config_gz-v2-1-f725d331fb5d@ixit.cz

Changes in v2:
- IKCONFIG is now module instead of built-in (Greg).
- Link to v1: https://lore.kernel.org/r/20230612210208.109267-1-david@ixit.cz
---
 arch/arm/configs/multi_v7_defconfig | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm/configs/multi_v7_defconfig b/arch/arm/configs/multi_v7_defconfig
index 65df4014c4a60..5180c90cb5da1 100644
--- a/arch/arm/configs/multi_v7_defconfig
+++ b/arch/arm/configs/multi_v7_defconfig
@@ -1,6 +1,8 @@
 CONFIG_SYSVIPC=y
 CONFIG_NO_HZ_IDLE=y
 CONFIG_HIGH_RES_TIMERS=y
+CONFIG_IKCONFIG=m
+CONFIG_IKCONFIG_PROC=y
 CONFIG_CGROUPS=y
 CONFIG_BLK_DEV_INITRD=y
 CONFIG_EXPERT=y

---
base-commit: f2b1f6a9f382564b1d4cf16c45e73ccccb917f1f
change-id: 20250329-arm-config_gz-7d656859ad59

Best regards,
-- 
David Heidelberg <david@ixit.cz>

