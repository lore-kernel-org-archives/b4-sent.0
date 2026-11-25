From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH v3 0/3] Add Cortina Systems CS7542 NAND controller support
Date: Wed, 25 Nov 2026 21:15:27 +0300
Message-Id: <20261125-b4-cs7542-nand-v3-0-0b6d141c102e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBQFr0K6tua3BUpZeQ/jAsoHaqSYFhsN4
 e62uHGjy0nezFuJR2fQkzpbicNgvJltBHHIiB4bOyA1XWTCgZeMcUHbnGovi5xT29iOVlIpiQI
 ApCJRujvszXMPni8f9o/2inpJlbQYjV9m99ofA0u7n/HAKFCpkUmlgTHkp2FqzO2o54mkeOD/d
 R511akeqhKqQuTf+rZtbxP7tc79AAAA
X-Change-ID: 20261123-b4-cs7542-nand-87997e300079
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-mtd@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795630527; l=5154;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=FxytYVQh1Bi01rQ9dueEmTxTm7lLV6AVOQ9uoQMr0ck=;
 b=ETC/jJXYJFGf9J0x7cJw9IJcjfyyNxoX+S+PdnQVFwhN3n3mnhF8wlsUudz0e7tD9PuvsqTME
 aqd2yTEZdKFCWL01PuA8JBQCRRLnND7tsGx4S27ZXCV48KjEVKiuxZH
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the NAND controller used by the Securifi Almond+ (CS7542, two Cortex-A9
CPUs). This is an independent binding/driver/MAINTAINERS series on
Linux v7.4-rc4; it does not depend on ARCH_CORTINA_ACCESS or the platform
series.

The controller sequences complete command/address/data transactions. Use
exec_op with explicit capability checking and cached ID, ONFI and page reads
for NAND core's split operations. Retain firmware-initialized bus timing.
This version supports large-page, 8-bit NAND with on-host Hamming ECC using
256-byte steps and the existing OOB layout. It uses programmed I/O; DMA and
unverified BCH modes are deliberately outside this initial implementation.

Validation:
- Full independent ARM vmlinux and modules builds, driver both =y and =m,
  COMPILE_TEST=n, without the platform series.
- Binding schema/example and strict source checkpatch pass.
- Actual decoder functions: 292 boundary, address and sequence cases under
  UBSAN. Address packing: 655360 cases cover every Almond+ page and
  two-row-cycle large-page geometries. Actual Hamming correction function: 20485 cases covering every
  single-data-bit position, invalid hardware offsets and error propagation.
- Linux 7.4-rc4 booted in RAM on Almond+. NAND identification, all-device
  bad-block scan, OOB reads and SHA256 of five existing protected regions
  passed without new ECC failures.
- The real UBI stack created a temporary two-LEB volume, wrote and verified
  two 253952-byte patterns, removed the volume and reattached with the
  original bad-block reserve. All 14 protected partition/configuration
  checksums matched after returning to installed OpenWrt 6.18.64; the five
  original UBI volumes and normal reserve remained intact.

V2 adds 630 actual attach-function geometry/ECC cases and repeats the full
independent ARM =y/=m builds. V2 also booted Linux 7.4 in RAM with a single
read-only partition: identification, bad-block scan, OOB reads and hashes
of six protected regions including calibration passed, with no new ECC
failures and automatic return to installed OpenWrt. The previous UBI
write test above was on v1; it was not repeated on v2.

On Almond+, I booted v3 in RAM with all 16 NAND partitions read-only.
I read and verified 56 MiB against SHA-256 hashes of seven existing
regions. Raw and generic OOB reads returned identical 64-byte buffers
in all four banks. ECC reported five corrections and no uncorrectable
errors. The fixed controller exposed no manual sysfs bind/unbind
controls. That run was read-only.

A subsequent Linux 7.4-rc4 RAM run used the unchanged v3 driver for a
fresh UBI write/erase test. It created a temporary two-LEB volume and
wrote and compared two 253952-byte patterns. Between the patterns,
UBI_IOCEBER erased both LEBs and flushed physical erasure; reading the
volume returned 253952 bytes of 0xff. The test removed only its newly
created volume and restored the original bad-block reserve. All five
original volumes, reserve 80/free 0/bad 0, 13 protected data hashes and
15 configuration files matched after watchdog returned to OpenWrt.
The four LCD services and normal watchdog were running afterward.

No kernel image was installed by these RAM tests. Board integration used
for testing is kept separate from this series.

---
Changes in v3:
- Honor the current interface tWB maximum before polling R/B.
- Suppress unsafe manual sysfs bind/unbind on fixed SoC flash.
- Add actual-function timing regressions and repeat ARM built-in/module builds.
- Link to v2: https://patch.msgid.link/20261123-b4-cs7542-nand-v2-0-9d9f08608534@gmail.com

Changes in v2:
- Reject unsupported page/OOB layouts and incompatible ECC requests.
- Use 64-bit arithmetic before extracting the page bank.
- Reject invalid hardware error-bit indices, preserve DT labels,
  use the core OOB write helper and standard final-read polling.
- Link to v1: https://patch.msgid.link/20261123-b4-cs7542-nand-v1-0-7ce179c011e2@gmail.com

To: Fil Dunsky <filipp.dunsky@gmail.com>
To: Miquel Raynal <miquel.raynal@bootlin.com>
To: Richard Weinberger <richard@nod.at>
To: Vignesh Raghavendra <vigneshr@ti.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: linux-mtd@lists.infradead.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Fil Dunsky (3):
      dt-bindings: mtd: Add Cortina CS7542 NAND controller
      mtd: rawnand: Add Cortina CS7542 controller support
      MAINTAINERS: Add Cortina CS7542 NAND controller entry

 .../bindings/mtd/cortina,cs7542-nand.yaml          |  66 ++
 MAINTAINERS                                        |   7 +
 drivers/mtd/nand/raw/Kconfig                       |  12 +
 drivers/mtd/nand/raw/Makefile                      |   1 +
 drivers/mtd/nand/raw/cs752x_nand.c                 | 814 +++++++++++++++++++++
 5 files changed, 900 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-nand-87997e300079

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

