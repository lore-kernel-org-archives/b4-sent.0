From: Junrui Luo <moonafterrain@outlook.com>
Date: Thu, 13 Aug 2026 16:08:24 +0800
Subject: [PATCH v2] coresight: configfs: print the address parameter with
 %pK
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-coresight-fixes-v2-1-096163d321db@outlook.com>
X-B4-Tracking: v=1; b=H4sIAHd7fWoC/3WNzQ6CMBCEX4Xs2Zr+ICIn38NwwLKFjcqatjYa0
 ne3cvf4zeSbWSGgJwzQVSt4TBSIlwJ6V4Gdh2VCQWNh0FI3slVaWPYYaJqjcPTGIE6Dk6MzRrW
 NhmI9PW5FkS594ZlCZP/ZDpL6pf+3khJKHIy7uhqPRtfqzK94Z77tLT+gzzl/ATQ7vXqwAAAA
X-Change-ID: 20260812-coresight-fixes-9af0df331862
To: Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Mike Leach <mike.leach@arm.com>, James Clark <james.clark@linaro.org>, 
 Leo Yan <leo.yan@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Linu Cherian <lcherian@marvell.com>
Cc: coresight@lists.linaro.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org, Junrui Luo <moonafterrain@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2893;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=39Yh9YwtTx5GJcnsVzhUE55SB3APLptbyhbni9ITWJ4=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrNrquvKfBks9Puc9LWxw27Ntz6+kixvPsWznlHhSW
 ZK9/LaN65KOUhYGMS4GWTFFluMFl75Z+G7R3eKzJRlmDisTyBAGLk4BmIjsIUaGn/vuTet8s/lc
 7uIQVaWI1P4FN1KPzDt4fNuUhOiIj1wmngz//WdvuysQ3Zdx/2dqVJ6t5lzBLTFNZ04kia/ZFH3
 /Se4NZgAwQ1AC
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The preloaded 'gen_etrig' ETMv4 feature declares its only parameter as
{ .name = "address", .value = (u64)panic }, so on a relocatable kernel
the stored value is the post-KASLR runtime address of panic().

cscfg_param_value_show() prints that value verbatim with "0x%llx", and
CONFIGFS_ATTR() gives the attribute mode 0644 while every enclosing
directory is 0755. Once configfs is mounted, any local user reading
cs-syscfg/features/gen_etrig/params/address/value can recover the kernel
text base; neither kptr_restrict nor a capability check applies on that
path, and the plain u64 print bypasses the pointer-formatting
protections. The parameter exists even without trace hardware, since
cscfg_init() calls cscfg_preload() unconditionally and
coresight-cfg-pstop.o is linked into the core coresight module.

Print a parameter named "address" with "%pK" instead, letting
kptr_restrict decide what an unprivileged reader gets. Parameters holding
plain numbers, such as the strobing 'window' and 'period' counts, keep
the "0x%llx" format.

Fixes: 4b7e62627a38 ("coresight: config: Add preloaded configuration")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Suggested-by: Leo Yan <leo.yan@arm.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
Changes in v2:
- Print a parameter named "address" with "%pK" in cscfg_param_value_show()
  instead of giving it a 0600 'value' attribute (Leo Yan).
- Link to v1: https://lore.kernel.org/r/20260812-coresight-fixes-v1-1-53fbf4e73241@outlook.com
---
 drivers/hwtracing/coresight/coresight-syscfg-configfs.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/hwtracing/coresight/coresight-syscfg-configfs.c b/drivers/hwtracing/coresight/coresight-syscfg-configfs.c
index 2b40e556be87..e084ed0b106b 100644
--- a/drivers/hwtracing/coresight/coresight-syscfg-configfs.c
+++ b/drivers/hwtracing/coresight/coresight-syscfg-configfs.c
@@ -281,7 +281,14 @@ static ssize_t cscfg_param_value_show(struct config_item *item, char *page)
 {
 	struct cscfg_fs_param *param_item = container_of(to_config_group(item),
 							 struct cscfg_fs_param, group);
-	u64 value = param_item->feat_desc->params_desc[param_item->param_idx].value;
+	struct cscfg_parameter_desc *param_desc =
+		&param_item->feat_desc->params_desc[param_item->param_idx];
+	u64 value = param_desc->value;
+
+	/* The kernel address should print with the "%pK" specifier */
+	if (!strcmp(param_desc->name, "address"))
+		return scnprintf(page, PAGE_SIZE, "0x%pK\n",
+				 (void *)(unsigned long)value);
 
 	return scnprintf(page, PAGE_SIZE, "0x%llx\n", value);
 }

---
base-commit: f5bbbfec59b4e2fb7520a91de3df8a6174325d6a
change-id: 20260812-coresight-fixes-9af0df331862

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

