From: Michael Reeves <michael.reeves077@gmail.com>
Date: Thu, 08 Oct 2026 23:15:41 +1100
Subject: [PATCH 2/2] arm64: Apply existing Apple CPU workarounds to M3 and
 M4
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-apple-m3-m4-kvm-v1-2-7bb4cbf3d63b@gmail.com>
References: <20261008-apple-m3-m4-kvm-v1-0-7bb4cbf3d63b@gmail.com>
In-Reply-To: <20261008-apple-m3-m4-kvm-v1-0-7bb4cbf3d63b@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791461740; l=1320;
 i=michael.reeves077@gmail.com; s=20261008-m3-m4-kvm;
 h=from:subject:message-id; bh=4DZxVFKEdF/Pu4GYU+OpToXoJYmi+szLHgZHQGkaf0M=;
 b=abXZoPRVUxn8QpLlM9NH1pz4/xpj6h3GJjVNe/wpQmf4rPCSbEySETEDlYQg8trN+7qvOD4b8
 FO5G/JfJ2FRBRnINns7srdp/CPX57G11XBwKnKf9G6NvfH+fnb8cNu4
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=oi7WuppQ1A+qFZp9DdfIwDnpC3WZ+XY6fJK1upV/CSY=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261008-m3-m4-kvm with auth_id=1131
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add M3, M3 Pro, M3 Max and base M4 to apple_cpus so they receive the
existing PMU trap and broken SEIS workarounds needed by KVM.

Co-developed-by: Yureka Lilian <yureka@cyberchaos.dev>
Signed-off-by: Yureka Lilian <yureka@cyberchaos.dev>
Tested-by: Yureka Lilian <yureka@cyberchaos.dev>
Tested-by: Myria Sarvay <myrialsarvay@gmail.com>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 arch/arm64/kernel/cpu_errata.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/kernel/cpu_errata.c b/arch/arm64/kernel/cpu_errata.c
index e0c094025..8a7703b86 100644
--- a/arch/arm64/kernel/cpu_errata.c
+++ b/arch/arm64/kernel/cpu_errata.c
@@ -288,6 +288,14 @@ static const struct midr_range apple_cpus[] = {
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
 	{},
 };
 

-- 
2.56.0

