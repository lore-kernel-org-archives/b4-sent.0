From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Thu, 18 Jan 2024 09:25:15 -0600
Subject: [PATCH RFC 4/5] powerpc/pseries: Prepare
 pseries_add_hw_description() for runtime use
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240118-update-dump-stack-arch-str-v1-4-5c0f98d017b5@linux.ibm.com>
References: <20240118-update-dump-stack-arch-str-v1-0-5c0f98d017b5@linux.ibm.com>
In-Reply-To: <20240118-update-dump-stack-arch-str-v1-0-5c0f98d017b5@linux.ibm.com>
To: "Aneesh Kumar K.V" <aneesh.kumar@linux.ibm.com>, 
 "Naveen N. Rao" <naveen.n.rao@linux.ibm.com>, 
 Brian King <brking@linux.ibm.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 John Ogness <john.ogness@linutronix.de>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Petr Mladek <pmladek@suse.com>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, 
 Steven Rostedt <rostedt@goodmis.org>
Cc: linux-kernel@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705591541; l=2099;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=CZv2kpuUutCPmlUb5oeOcKP+Rm48SwsyFZd4IK8M0MI=;
 b=VVNznsHiVwe7zaiA0/fbe8MyMpQpbpoQiulJKy7zUG3wlvgn6w2XdK5QLCzzLofZfATALOCz8
 dlidtlO/FPgAkWxOCQuJcyLT2ARRHAF958I6ehHVXDfd352+MaTHxLt
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pseries_add_hw_description() will be used after boot to update the
hardware description string emitted in stack dumps. Remove the __init
and make it take a seq_buf * parameter instead of referencing
ppc_hw_desc directly.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/platforms/pseries/setup.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/arch/powerpc/platforms/pseries/setup.c b/arch/powerpc/platforms/pseries/setup.c
index ecea85c74c43..9ae1951f8312 100644
--- a/arch/powerpc/platforms/pseries/setup.c
+++ b/arch/powerpc/platforms/pseries/setup.c
@@ -1007,7 +1007,7 @@ static void __init pSeries_cmo_feature_init(void)
 	pr_debug(" <- fw_cmo_feature_init()\n");
 }
 
-static void __init pseries_add_hw_description(void)
+static void pseries_add_hw_description(struct seq_buf *sb)
 {
 	struct device_node *dn;
 	const char *s;
@@ -1015,7 +1015,7 @@ static void __init pseries_add_hw_description(void)
 	dn = of_find_node_by_path("/openprom");
 	if (dn) {
 		if (of_property_read_string(dn, "model", &s) == 0)
-			seq_buf_printf(&ppc_hw_desc, "of:%s ", s);
+			seq_buf_printf(sb, "of:%s ", s);
 
 		of_node_put(dn);
 	}
@@ -1023,7 +1023,7 @@ static void __init pseries_add_hw_description(void)
 	dn = of_find_node_by_path("/hypervisor");
 	if (dn) {
 		if (of_property_read_string(dn, "compatible", &s) == 0)
-			seq_buf_printf(&ppc_hw_desc, "hv:%s ", s);
+			seq_buf_printf(sb, "hv:%s ", s);
 
 		of_node_put(dn);
 		return;
@@ -1031,7 +1031,7 @@ static void __init pseries_add_hw_description(void)
 
 	if (of_property_read_bool(of_root, "ibm,powervm-partition") ||
 	    of_property_read_bool(of_root, "ibm,fw-net-version"))
-		seq_buf_printf(&ppc_hw_desc, "hv:phyp ");
+		seq_buf_printf(sb, "hv:phyp ");
 }
 
 /*
@@ -1041,7 +1041,7 @@ static void __init pseries_init(void)
 {
 	pr_debug(" -> pseries_init()\n");
 
-	pseries_add_hw_description();
+	pseries_add_hw_description(&ppc_hw_desc);
 
 #ifdef CONFIG_HVC_CONSOLE
 	if (firmware_has_feature(FW_FEATURE_LPAR))

-- 
2.43.0

