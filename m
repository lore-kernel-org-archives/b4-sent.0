From: Michael Reeves <michael.reeves077@gmail.com>
Date: Wed, 21 Oct 2026 10:53:21 +1100
Subject: [PATCH v2 2/2] arm64: Apply existing Apple Silicon CPU workarounds
 to newer CPUs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-apple-m3-m4-kvm-v2-2-04905152cc2a@gmail.com>
References: <20261021-apple-m3-m4-kvm-v2-0-04905152cc2a@gmail.com>
In-Reply-To: <20261021-apple-m3-m4-kvm-v2-0-04905152cc2a@gmail.com>
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oupton@kernel.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Mark Rutland <mark.rutland@arm.com>
Cc: Myria Sarvay <myrialsarvay@gmail.com>, 
 Yureka Lilian <yureka@cyberchaos.dev>, Fuad Tabba <fuad.tabba@linux.dev>, 
 Joey Gouly <joey.gouly@arm.com>, Steffen Eiden <seiden@linux.ibm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, linux-arm-kernel@lists.infradead.org, 
 kvmarm@lists.linux.dev, Sven Peter <sven@kernel.org>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 asahi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792540400; l=2838;
 i=michael.reeves077@gmail.com; s=20261008-m3-m4-kvm;
 h=from:subject:message-id; bh=PFEvneEC+/aHCyp+lZlYQ70fLEswRlQt4crDxkng4ZM=;
 b=tdzSqkZ6HaKIHAWImFyWY66JwbtNxJmwuTwJTnGZZiLnX6q5CW+eemkITphNFG4ER38EIwCOr
 6m8dQm1oFgJBeqMtTnFaL2l0m6ROA2s5BnrD3vmK7nq+4wKb+MQO9vF
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=oi7WuppQ1A+qFZp9DdfIwDnpC3WZ+XY6fJK1upV/CSY=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261008-m3-m4-kvm with auth_id=1131
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add M3, M3 Pro, M3 Max, base M4, A18 Pro and M5 Pro to apple_cpus
so they receive the existing PMU trap and broken SEIS workarounds.

Add these CPUs to has_vgic_v3 so KVM detects TDIR support and can
trap guest DIR accesses without trapping all common registers.

Co-developed-by: Yureka Lilian <yureka@cyberchaos.dev>
Signed-off-by: Yureka Lilian <yureka@cyberchaos.dev>
Tested-by: Yureka Lilian <yureka@cyberchaos.dev>
Tested-by: Myria Sarvay <myrialsarvay@gmail.com>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 arch/arm64/kernel/cpu_errata.c | 12 ++++++++++++
 arch/arm64/kernel/cpufeature.c | 12 ++++++++++++
 2 files changed, 24 insertions(+)

diff --git a/arch/arm64/kernel/cpu_errata.c b/arch/arm64/kernel/cpu_errata.c
index e0c094025..bc91bc13b 100644
--- a/arch/arm64/kernel/cpu_errata.c
+++ b/arch/arm64/kernel/cpu_errata.c
@@ -288,6 +288,18 @@ static const struct midr_range apple_cpus[] = {
 	MIDR_ALL_VERSIONS(MIDR_APPLE_M2_AVALANCHE_PRO),
 	MIDR_ALL_VERSIONS(MIDR_APPLE_M2_BLIZZARD_MAX),
 	MIDR_ALL_VERSIONS(MIDR_APPLE_M2_AVALANCHE_MAX),
+	MIDR_ALL_VERSIONS(MIDR_APPLE_M3_SAWTOOTH),
+	MIDR_ALL_VERSIONS(MIDR_APPLE_M3_EVEREST),
+	MIDR_ALL_VERSIONS(MIDR_APPLE_M3_SAWTOOTH_PRO),
+	MIDR_ALL_VERSIONS(MIDR_APPLE_M3_EVEREST_PRO),
+	MIDR_ALL_VERSIONS(MIDR_APPLE_M3_SAWTOOTH_MAX),
+	MIDR_ALL_VERSIONS(MIDR_APPLE_M3_EVEREST_MAX),
+	MIDR_ALL_VERSIONS(MIDR_APPLE_M4_DONAN_ECORE),
+	MIDR_ALL_VERSIONS(MIDR_APPLE_M4_DONAN_PCORE),
+	MIDR_ALL_VERSIONS(MIDR_APPLE_A18_PRO_TAHITI_ECORE),
+	MIDR_ALL_VERSIONS(MIDR_APPLE_A18_PRO_TAHITI_PCORE),
+	MIDR_ALL_VERSIONS(MIDR_APPLE_M5_PRO_SOTRA_MCORE),
+	MIDR_ALL_VERSIONS(MIDR_APPLE_M5_PRO_SOTRA_PCORE),
 	{},
 };
 
diff --git a/arch/arm64/kernel/cpufeature.c b/arch/arm64/kernel/cpufeature.c
index 3ae3ad1a1..bb82b80b3 100644
--- a/arch/arm64/kernel/cpufeature.c
+++ b/arch/arm64/kernel/cpufeature.c
@@ -2357,6 +2357,18 @@ static bool can_trap_icv_dir_el1(const struct arm64_cpu_capabilities *entry,
 		MIDR_ALL_VERSIONS(MIDR_APPLE_M2_AVALANCHE_PRO),
 		MIDR_ALL_VERSIONS(MIDR_APPLE_M2_BLIZZARD_MAX),
 		MIDR_ALL_VERSIONS(MIDR_APPLE_M2_AVALANCHE_MAX),
+		MIDR_ALL_VERSIONS(MIDR_APPLE_M3_SAWTOOTH),
+		MIDR_ALL_VERSIONS(MIDR_APPLE_M3_EVEREST),
+		MIDR_ALL_VERSIONS(MIDR_APPLE_M3_SAWTOOTH_PRO),
+		MIDR_ALL_VERSIONS(MIDR_APPLE_M3_EVEREST_PRO),
+		MIDR_ALL_VERSIONS(MIDR_APPLE_M3_SAWTOOTH_MAX),
+		MIDR_ALL_VERSIONS(MIDR_APPLE_M3_EVEREST_MAX),
+		MIDR_ALL_VERSIONS(MIDR_APPLE_M4_DONAN_ECORE),
+		MIDR_ALL_VERSIONS(MIDR_APPLE_M4_DONAN_PCORE),
+		MIDR_ALL_VERSIONS(MIDR_APPLE_A18_PRO_TAHITI_ECORE),
+		MIDR_ALL_VERSIONS(MIDR_APPLE_A18_PRO_TAHITI_PCORE),
+		MIDR_ALL_VERSIONS(MIDR_APPLE_M5_PRO_SOTRA_MCORE),
+		MIDR_ALL_VERSIONS(MIDR_APPLE_M5_PRO_SOTRA_PCORE),
 		{},
 	};
 	struct arm_smccc_res res = {};

-- 
2.56.0

