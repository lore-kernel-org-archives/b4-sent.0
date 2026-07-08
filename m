From: Sven Peter <sven@kernel.org>
Date: Wed, 08 Jul 2026 09:15:41 +0200
Subject: [PATCH RFC 5/6] firmware/psci: Add EFI runtime conduit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-efi-psci-v1-5-9efb3abf0e4c@kernel.org>
References: <20260708-efi-psci-v1-0-9efb3abf0e4c@kernel.org>
In-Reply-To: <20260708-efi-psci-v1-0-9efb3abf0e4c@kernel.org>
To: Mark Rutland <mark.rutland@arm.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Ard Biesheuvel <ardb@kernel.org>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Sudeep Holla <sudeep.holla@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-efi@vger.kernel.org, 
 asahi@lists.linux.dev, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4276; i=sven@kernel.org;
 h=from:subject:message-id; bh=Inmjc7fy2KHCPtWNbqaEGcDOCoTWrKNk24udNuAiX/Q=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ5bvT23luh6jNRmec1i/zfwgLh37Z3XochFpTrvb7ybPi
 f/qH7Ggo5SFQYyLQVZMkWX7fnvTJw/fCC7ddOk9zBxWJpAhDFycAjARbx+G/5UnObc9rFeO2jJR
 LuD0u3VzzCY1Of3eHFblG+C9UbP0wk1Ghna5/cuSDr+zmtEQMcVq4jaHp98DlQXLDh5mrt+22+Y
 TLzsA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apple Silicon machines run the kernel at the highest available exception
level, leaving no higher level to trap into for PSCI firmware calls. The
firmware implementing PSCI therefore shares that level with the kernel and
is exposed as an EFI runtime service instead of being reached through an
SMC or HVC trap.

Add a new "efi" conduit that routes PSCI calls to the handler extracted
from the custom EFI configuration table.

PSCI_VERSION, MIGRATE_INFO_TYPE and PSCI_FEATURES are queried during early
CPU bring-up before EFI runtime services are available and have to be
answered directly from the firmware-provided table.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/firmware/psci/psci.c | 64 ++++++++++++++++++++++++++++++++++++++++++++
 include/linux/arm-smccc.h    |  1 +
 2 files changed, 65 insertions(+)

diff --git a/drivers/firmware/psci/psci.c b/drivers/firmware/psci/psci.c
index e73bae6cb23a..af022bf2cb9f 100644
--- a/drivers/firmware/psci/psci.c
+++ b/drivers/firmware/psci/psci.c
@@ -10,6 +10,7 @@
 #include <linux/arm-smccc.h>
 #include <linux/cpuidle.h>
 #include <linux/debugfs.h>
+#include <linux/efi.h>
 #include <linux/errno.h>
 #include <linux/linkage.h>
 #include <linux/of.h>
@@ -24,6 +25,7 @@
 
 #include <asm/cpuidle.h>
 #include <asm/cputype.h>
+#include <asm/efi.h>
 #include <asm/hypervisor.h>
 #include <asm/system_misc.h>
 #include <asm/smp_plat.h>
@@ -131,6 +133,63 @@ __invoke_psci_fn_smc(unsigned long function_id,
 	return res.a0;
 }
 
+#if IS_ENABLED(CONFIG_EFI) && IS_ENABLED(CONFIG_ARM64)
+static bool efi_psci_fn_valid(unsigned long function_id)
+{
+	if (function_id >= PSCI_0_2_FN_BASE &&
+	    function_id <= PSCI_0_2_FN(EFI_PSCI_MAX_FN))
+		return true;
+
+	if (function_id >= PSCI_0_2_FN64_BASE &&
+	    function_id <= PSCI_0_2_FN64(EFI_PSCI_MAX_FN))
+		return true;
+
+	return false;
+}
+
+static unsigned long __invoke_psci_fn_efi(unsigned long function_id,
+					  unsigned long arg0,
+					  unsigned long arg1,
+					  unsigned long arg2)
+{
+	u32 fn;
+
+	/* These are called before EFI runtime services are available */
+	switch (function_id) {
+	case PSCI_0_2_FN_PSCI_VERSION:
+		return efi_psci.version;
+	case PSCI_0_2_FN_MIGRATE_INFO_TYPE:
+		return PSCI_0_2_TOS_MP;
+	case PSCI_1_0_FN_PSCI_FEATURES:
+		if (!efi_psci_fn_valid(arg0))
+			return PSCI_RET_NOT_SUPPORTED;
+		fn = arg0 & 0xff;
+		if (fn >= efi_psci.num_features || fn >= EFI_PSCI_MAX_FN)
+			return PSCI_RET_NOT_SUPPORTED;
+		return efi_psci.features[fn];
+	}
+
+	if (!efi_psci_fn_valid(function_id))
+		return PSCI_RET_NOT_SUPPORTED;
+
+	if (WARN_ON_ONCE(!efi_psci.psci_handler))
+		return PSCI_RET_NOT_SUPPORTED;
+	if (WARN_ON_ONCE(!efi_enabled(EFI_RUNTIME_SERVICES)))
+		return PSCI_RET_NOT_SUPPORTED;
+
+	return arm64_efi_psci_call(function_id, arg0, arg1, arg2);
+}
+#else
+static unsigned long __invoke_psci_fn_efi(unsigned long function_id,
+					  unsigned long arg0,
+					  unsigned long arg1,
+					  unsigned long arg2)
+{
+	WARN(1, "EFI PSCI conduit invoked but kernel has not EFI support");
+	return PSCI_RET_NOT_SUPPORTED;
+}
+#endif
+
 static __always_inline int psci_to_linux_errno(int errno)
 {
 	switch (errno) {
@@ -277,6 +336,9 @@ static void set_conduit(enum arm_smccc_conduit conduit)
 	case SMCCC_CONDUIT_SMC:
 		invoke_psci_fn = __invoke_psci_fn_smc;
 		break;
+	case SMCCC_CONDUIT_EFI:
+		invoke_psci_fn = __invoke_psci_fn_efi;
+		break;
 	default:
 		WARN(1, "Unexpected PSCI conduit %d\n", conduit);
 	}
@@ -299,6 +361,8 @@ static int get_set_conduit_method(const struct device_node *np)
 		set_conduit(SMCCC_CONDUIT_HVC);
 	} else if (!strcmp("smc", method)) {
 		set_conduit(SMCCC_CONDUIT_SMC);
+	} else if (!strcmp("efi", method)) {
+		set_conduit(SMCCC_CONDUIT_EFI);
 	} else {
 		pr_warn("invalid \"method\" property: %s\n", method);
 		return -EINVAL;
diff --git a/include/linux/arm-smccc.h b/include/linux/arm-smccc.h
index 4de81848fe2e..7328e1e222ca 100644
--- a/include/linux/arm-smccc.h
+++ b/include/linux/arm-smccc.h
@@ -322,6 +322,7 @@ enum arm_smccc_conduit {
 	SMCCC_CONDUIT_NONE,
 	SMCCC_CONDUIT_SMC,
 	SMCCC_CONDUIT_HVC,
+	SMCCC_CONDUIT_EFI,
 };
 
 /**

-- 
2.55.0

