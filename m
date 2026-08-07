From: "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
Date: Fri, 07 Aug 2026 13:38:33 +0100
Subject: [PATCH] platform/x86: olpc-xo15-sci: use named initializers for
 acpi_device_id
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260807-acpi-platform-v1-1-1507662916ed@thegoodpenguin.co.uk>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSw5AMBRA0a3IG2tSlfptRQyqXnni07SIROxdM
 TyDey/w6Ag9VNEFDg/ytC4BSRyBHtTSI6MuGAQXGS94zpS2xOykNrO6mWXStFIIbdJSQmisQ0P
 n96ub335vR9TbO4H7fgAiB9LncQAAAA==
X-Change-ID: 20260807-acpi-platform-65fb522cf395
To: Thomas Gleixner <tglx@kernel.org>, Ingo Molnar <mingo@redhat.com>, 
 Borislav Petkov <bp@alien8.de>, Dave Hansen <dave.hansen@linux.intel.com>, 
 x86@kernel.org, "H. Peter Anvin" <hpa@zytor.com>
Cc: linux-kernel@vger.kernel.org, 
 "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786106327; l=1292;
 i=pzalewski@thegoodpenguin.co.uk; s=20260803; h=from:subject:message-id;
 bh=GiuZy2AkLGOTalI0u3slCSx569cbFLpbYf6BitVGB7E=;
 b=KchVjnBAnzZUZ9AoTmDCZ+/jQPs1tUz2Wqsxgb8PtuVyLE5cTjCiPTIR859qmhQLk9fzqnmpP
 +jqmV3CyKx7C4fs2h03GNhLDwMAYkc8N1i+sAsEouVt9du5ccueJYXA
X-Developer-Key: i=pzalewski@thegoodpenguin.co.uk; a=ed25519;
 pk=W3zk1cb/wRnj6pNGbl3/2Zf3GmPA6IBpNHpDPyJ05k8=
X-Endpoint-Received: by B4 Relay for pzalewski@thegoodpenguin.co.uk/20260803 with auth_id=913
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use a named initializer for the acpi_device_id fields which
makes the code more readable and consistent with how lists
are initialized in the rest of the kernel code base. Also
drop explicitly setting fields to 0 where it is redundant.

While we are at it - unify the list terminator to have
a single space between the brackets and no trailing
comma.

Signed-off-by: Pawel Zalewski (The Capable Hub) <pzalewski@thegoodpenguin.co.uk>
---
 arch/x86/platform/olpc/olpc-xo15-sci.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/x86/platform/olpc/olpc-xo15-sci.c b/arch/x86/platform/olpc/olpc-xo15-sci.c
index e486109e88c8..4b2dc77410a6 100644
--- a/arch/x86/platform/olpc/olpc-xo15-sci.c
+++ b/arch/x86/platform/olpc/olpc-xo15-sci.c
@@ -215,8 +215,8 @@ static int xo15_sci_resume(struct device *dev)
 static SIMPLE_DEV_PM_OPS(xo15_sci_pm, NULL, xo15_sci_resume);
 
 static const struct acpi_device_id xo15_sci_device_ids[] = {
-	{"XO15EC", 0},
-	{"", 0},
+	{ .id = "XO15EC" },
+	{ }
 };
 
 static struct platform_driver xo15_sci_drv = {

---
base-commit: f9a2394a23482bfd330911e9c8295b71724feacd
change-id: 20260807-acpi-platform-65fb522cf395

Best regards,
--  
Pawel Zalewski (The Capable Hub) <pzalewski@thegoodpenguin.co.uk>

