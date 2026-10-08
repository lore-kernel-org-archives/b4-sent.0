From: Michael Reeves <michael.reeves077@gmail.com>
Subject: [PATCH 0/2] arm64: Add support for Apple M3 and M4 CPUs in KVM
Date: Thu, 08 Oct 2026 23:15:39 +1100
Message-Id: <20261008-apple-m3-m4-kvm-v1-0-7bb4cbf3d63b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGuJx2oC/yWMyw6DIBBFf8XMupMiGvv4laYLBsZKW5CANU2M/
 y7o8tzHWSBxtJzgXi0QebbJjj5DfapAD8q/GK3JDFLIrhbiiiqEL6Nr0LX4mR3ShW4kuWlJG8i
 vELm3/934eB6cfvRmPRVNWZBKjBSV10OJTFT9dD60uzDXsK4bk1jkupoAAAA=
X-Change-ID: 20261008-apple-m3-m4-kvm-b7b9b2e34bcd
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791461739; l=982;
 i=michael.reeves077@gmail.com; s=20261008-m3-m4-kvm;
 h=from:subject:message-id; bh=4ODUPMV03VdBemqJmmhvAVMXz/2NymhIvG+Z8fEazdk=;
 b=k9godCQ6k6IjLO6XtMj7BaWGkvsuz4j44cDDnNlgk3dwYIILYaqrFQ97KPhtRllK9LFE+rJd8
 0aEIs/00G9xCt0t6+sdBFeJJ0xjg+9U/gDMEq966ZXDfR7WTihdCdDr
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=oi7WuppQ1A+qFZp9DdfIwDnpC3WZ+XY6fJK1upV/CSY=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261008-m3-m4-kvm with auth_id=1131
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series enables KVM support on Apple Silicon M3 series and base M4
CPUs.

The first patch adds the part numbers and MIDR definitions for M3
(base, Pro and Max) and base M4 CPU cores.

The second patch adds these CPUs to the existing Apple CPU workarounds
list, which is required for KVM to function correctly.

This series was developed from testing on:
- Apple M3 and M3 Pro by Michael Reeves
- Apple M3 Max by Myria Sarvay and Yureka Lilian
- Apple M4 by Yureka Lilian

---
Michael Reeves (1):
      arm64: Apply existing Apple CPU workarounds to M3 and M4

Myria Sarvay (1):
      arm64: Add Apple M3 and M4 CPU part numbers

 arch/arm64/include/asm/cputype.h | 16 ++++++++++++++++
 arch/arm64/kernel/cpu_errata.c   |  8 ++++++++
 2 files changed, 24 insertions(+)
---
base-commit: a90ee4305c4a5df72c11b31dacfdc76e00fcf78a
change-id: 20261008-apple-m3-m4-kvm-b7b9b2e34bcd

Best regards,
--  
Michael Reeves <michael.reeves077@gmail.com>

