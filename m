From: Michael Reeves <michael.reeves077@gmail.com>
Subject: [PATCH v2 0/2] arm64: Add KVM support for newer Apple Silicon CPUs
Date: Wed, 21 Oct 2026 10:53:19 +1100
Message-Id: <20261021-apple-m3-m4-kvm-v2-0-04905152cc2a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO/+12oC/3WOQQ6CMBBFr2K6drQUAurKexgWnXaAKgXSYqMh3
 N0W1i7fzP8vf2GenCHPboeFOQrGm3GIII4Hpjo5tARGR2aCizLj/AJymnoCm4Mt4BUsYIVXFJQ
 XqDSLrclRYz6b8VHv7N/4JDUnTUqg9ATo5KC6dNJONvN5127C+E6xzvh5dN9tWciS7v+IkAGHC
 rFQ2OS6zPHeWmn6kxotq9d1/QE4rRLf5wAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792540400; l=1504;
 i=michael.reeves077@gmail.com; s=20261008-m3-m4-kvm;
 h=from:subject:message-id; bh=G8igJOGmolem0kocmF21BJtoXeYx1AMIyTFUWr2XhNg=;
 b=3/imRnUx82pjDBOxQMAxCwDKByTwQ/pGjZVTqRy7jTjfXcIpKtcapYnyJgcn0m0DpETbDD76T
 CByrM5Dp/QaBW1o/MLetC4O2gExoXOB0vaJrXCtXkvMWIPOsb/Elnyr
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=oi7WuppQ1A+qFZp9DdfIwDnpC3WZ+XY6fJK1upV/CSY=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261008-m3-m4-kvm with auth_id=1131
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series enables KVM support on Apple Silicon M3 (base, Pro and Max),
base M4, A18 Pro and M5 Pro CPUs.

The first patch adds the CPU part numbers and MIDR definitions.

The second patch adds these CPUs to the existing Apple Silicon PMU and
broken SEIS workarounds. It also enables TDIR detection so KVM can trap
guest DIR accesses without trapping all common registers.

This series was developed from testing on:
- Apple M3 and M3 Pro by Michael Reeves
- Apple M3 Max by Myria Sarvay and Yureka Lilian
- Apple M4, A18 Pro and M5 Pro by Yureka Lilian

These tests also confirmed that the SEIS workaround is still needed.

---
Changes in v2:
- Add A18 Pro and M5 CPU IDs and workaround coverage.
- Add all to has_vgic_v3 for TDIR detection
- Document testing confirming SEIS workaround still needed
- Link to v1:
  https://patch.msgid.link/20261008-apple-m3-m4-kvm-v1-0-7bb4cbf3d63b@gmail.com

---
Michael Reeves (1):
      arm64: Apply existing Apple Silicon CPU workarounds to newer CPUs

Myria Sarvay (1):
      arm64: Add CPU part numbers for newer Apple Silicon CPUs

 arch/arm64/include/asm/cputype.h | 28 ++++++++++++++++++++++++++++
 arch/arm64/kernel/cpu_errata.c   | 12 ++++++++++++
 arch/arm64/kernel/cpufeature.c   | 12 ++++++++++++
 3 files changed, 52 insertions(+)
---
base-commit: a90ee4305c4a5df72c11b31dacfdc76e00fcf78a
change-id: 20261008-apple-m3-m4-kvm-b7b9b2e34bcd

Best regards,
--  
Michael Reeves <michael.reeves077@gmail.com>

