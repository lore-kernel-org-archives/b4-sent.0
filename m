From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Thu, 18 Jan 2024 09:25:16 -0600
Subject: [PATCH RFC 5/5] powerpc/pseries: Update hardware description
 string after migration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240118-update-dump-stack-arch-str-v1-5-5c0f98d017b5@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705591541; l=4664;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=yLmHE9ThZlzMbb6aloXvN4gTgnWJfDyfG66G809WhB4=;
 b=Q+37SjK8zZS4Tun8c+TodJT0/xdTHbgWsnBNDyyUECvL05LqqXalJJi38TeuCBXrRQu3g/dT8
 C/f58x/aq0iDCDQFi4PKjSRId3cA59UKDsExSucwkOSohtWaW/rYYO6
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce code that rebuilds the short hardware description printed by
stack traces. This sort of duplicates some code from boot (prom.c
mainly), but that code populates the string as early as possible using
APIs that aren't available later. So sharing all the code between the
boot and runtime versions isn't feasible.

To prevent "drift" between the boot and runtime versions, rebuild the
description using the new runtime APIs in a late initcall and warn if
it doesn't match the one built earlier. The initcall also invokes
dump_stack_update_arch_desc() twice to fully exercise it before any
partition migration occurs. These checks could be dropped or made
configurable later.

Call pseries_update_hw_description() immediately after updating the
device tree when resuming from a partition migration.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/platforms/pseries/mobility.c |  5 +++
 arch/powerpc/platforms/pseries/pseries.h  |  1 +
 arch/powerpc/platforms/pseries/setup.c    | 70 +++++++++++++++++++++++++++++++
 3 files changed, 76 insertions(+)

diff --git a/arch/powerpc/platforms/pseries/mobility.c b/arch/powerpc/platforms/pseries/mobility.c
index 1798f0f14d58..ff573cb5aee5 100644
--- a/arch/powerpc/platforms/pseries/mobility.c
+++ b/arch/powerpc/platforms/pseries/mobility.c
@@ -378,6 +378,11 @@ void post_mobility_fixup(void)
 	rc = pseries_devicetree_update(MIGRATION_SCOPE);
 	if (rc)
 		pr_err("device tree update failed: %d\n", rc);
+	/*
+	 * Rebuild the hardware description printed in stack traces
+	 * using the updated device tree.
+	 */
+	pseries_update_hw_description();
 
 	cacheinfo_rebuild();
 
diff --git a/arch/powerpc/platforms/pseries/pseries.h b/arch/powerpc/platforms/pseries/pseries.h
index bba4ad192b0f..810a64fccc7e 100644
--- a/arch/powerpc/platforms/pseries/pseries.h
+++ b/arch/powerpc/platforms/pseries/pseries.h
@@ -56,6 +56,7 @@ extern int dlpar_acquire_drc(u32 drc_index);
 extern int dlpar_release_drc(u32 drc_index);
 extern int dlpar_unisolate_drc(u32 drc_index);
 extern void post_mobility_fixup(void);
+void pseries_update_hw_description(void);
 
 void queue_hotplug_event(struct pseries_hp_errorlog *hp_errlog);
 int handle_dlpar_errorlog(struct pseries_hp_errorlog *hp_errlog);
diff --git a/arch/powerpc/platforms/pseries/setup.c b/arch/powerpc/platforms/pseries/setup.c
index 9ae1951f8312..72177411026e 100644
--- a/arch/powerpc/platforms/pseries/setup.c
+++ b/arch/powerpc/platforms/pseries/setup.c
@@ -1034,6 +1034,76 @@ static void pseries_add_hw_description(struct seq_buf *sb)
 		seq_buf_printf(sb, "hv:phyp ");
 }
 
+static void pseries_rebuild_hw_desc(struct seq_buf *sb)
+{
+	struct device_node *cpudn, *root;
+	const char *model;
+	u32 cpu_version;
+
+	seq_buf_clear(sb);
+
+	root = of_find_node_by_path("/");
+	if (!of_property_read_string(root, "model", &model))
+		seq_buf_printf(sb, "%s ", model);
+	of_node_put(root);
+
+	seq_buf_printf(sb, "%s 0x%04lx ", cur_cpu_spec->cpu_name, mfspr(SPRN_PVR));
+
+	cpudn = of_get_next_cpu_node(NULL);
+	if (!of_property_read_u32(cpudn, "cpu-version", &cpu_version)) {
+		if ((cpu_version & 0xff000000) == 0x0f000000)
+			seq_buf_printf(sb, "0x%04x ", cpu_version);
+	}
+	of_node_put(cpudn);
+
+	pseries_add_hw_description(sb);
+
+	seq_buf_puts(sb, ppc_md.name);
+}
+
+void pseries_update_hw_description(void)
+{
+	struct seq_buf sb = { // todo: use DECLARE_SEQ_BUF() once it's fixed
+		.buffer = (char[128]) { 0 },
+		.size = sizeof(char[128]),
+	};
+
+	pseries_rebuild_hw_desc(&sb);
+	dump_stack_update_arch_desc("%s", seq_buf_str(&sb));
+}
+
+static int __init pseries_test_update_hw_desc(void)
+{
+	struct seq_buf sb = { // todo: use DECLARE_SEQ_BUF() once it's fixed
+		.buffer = (char[128]) { 0 },
+		.size = sizeof(char[128]),
+	};
+	bool mismatch;
+
+	/*
+	 * Ensure the rebuilt description matches the one built during
+	 * boot.
+	 */
+	pseries_rebuild_hw_desc(&sb);
+
+	mismatch = strcmp(seq_buf_str(&ppc_hw_desc), seq_buf_str(&sb));
+	if (WARN(mismatch, "rebuilt hardware description string mismatch")) {
+		pr_err("  boot:    '%s'\n", ppc_hw_desc.buffer);
+		pr_err("  runtime: '%s'\n", sb.buffer);
+		return -EINVAL;
+	}
+
+	/*
+	 * Invoke dump_stack_update_arch_desc() *twice* to ensure it
+	 * exercises the free path.
+	 */
+	dump_stack_update_arch_desc("%s", sb.buffer);
+	dump_stack_update_arch_desc("%s", sb.buffer);
+
+	return 0;
+}
+late_initcall(pseries_test_update_hw_desc);
+
 /*
  * Early initialization.  Relocation is on but do not reference unbolted pages
  */

-- 
2.43.0

