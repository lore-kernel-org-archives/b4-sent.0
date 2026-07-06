From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH v2 0/6] target/loongarch: Fixes for endianness problems in
 vector instruction emulation
Date: Tue, 07 Jul 2026 04:02:00 +0800
Message-Id: <20260707-loong64-be-v2-0-8634f93c1dc9@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALkJTGoC/23MQQ7CIBCF4as0s3YMEAHrynuYLpBO20na0oAhm
 oa7i127/F/yvh0SRaYEt2aHSJkTh7WGOjXgJ7eOhNzXBiWUEVZInENYR3PBJ6Hrh6uT2lg9SKi
 HLdLA7wN7dLUnTq8QP4ed5W/9y2SJAltve6NJCNPa+7g4ns8+LNCVUr5AqYrkpAAAAA==
X-Change-ID: 20260701-loong64-be-adf8a15675f1
To: qemu-devel@nongnu.org
Cc: Song Gao <gaosong@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Richard Henderson <richard.henderson@linaro.org>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@oss.qualcomm.com>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2330;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=EwaW3pLq+EWjGl8zIVn1ure7hbbIgZjUsSKbTMpSl9w=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTAnOa/5OZrGymVeNI7kxHd8DfHOKVnvA8o9t/
 hxfVydtGj2JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakwJzgAKCRCwMePKe/7Z
 btlgD/0VfCXdMOds3aYqYTAjqrRwMfTh6eeh/DeUK2neQHDN6W8+iMvpz2c5VqkGlqRu9MGo9ME
 2H8mefJ5CdOVMhzhMVWxfOE7UajBqpgzqOWfRgm5gLughE+RrzAEja0BLcU/56B7Z4OiRUczKEF
 ez0RyxmvbLav25lFlGd/CFYwpYh+mLvNBtrMI+N9Pu5sIes7GiIEJrEQrDD63WM7bYF0QAvhQPn
 nVaz2d1ASkLlQAtmJg7ZkOQZ7LvQmn+8fVRO+HwDPmcTt7NEnC9GkMBNXKNj8l9x18L0YBCmsaJ
 gQWuWr8cTJm8PfolGsk1txNVIxEOj9+d3CJSD7/AKonJmiv6CXdhpBEm9+gmn21zgM7yJuI28V6
 LUHyo5cFm9Wu1N78ewggUGHbW/FW90AGrJMWlGAljg9jrm6QEJAsZvQVlyuvBod+UTCLNukPs5/
 T7MxHuBp2UdNaM6zAOJDgQr0ubpatX12euTV/sk+L289eaaGpMA9YVf0GHkkbdVI871gSfZlwud
 tqXjKRsxHK+hqEBsL2dEKDf2qVveGchaCWwKpEF9AfI1U7Q549RSm91Fl/Q6QKquijow8tbi4jT
 VkWjLRJrMmmFTEghSTR1nL+GOx90NWxKEQhI3+GfQif9yJuVSrhgOSGzpTYTtOiKt5pYrUhANBs
 JYWQNNmvMl4JY3Q==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The current implementation of vector instruction emulation in loongarch
target works illy on big endianness hosts. It can be reproduced using
the test cases from gcc [1]. One can cross-compile the target
loongarch64-linux-user for s390x and use qemu-s390x to run the compiled
qemu to test loongarch64 emulation on big endian hosts.

Possible reproduce steps are:

1. Install s390x cross toolchains and qemu-s390x
2. Compile qemu using ./configure --target-list=loongarch64-linux-user --cross-prefix=s390x-linux-gnu-
3. Install loongarch64 cross toolchains to compile the test cases. To
   get an accurate result, the test cases should be compiled using -O0.
   To make the error output of the test cases readable and meaningful,
   printf() should be replaced with a version without any vectorization
   optimizations, since the endianness problems will prevent printf()
   with lsx optimizations from working correctly
4. Use qemu-s390x ./qemu-loongarch64 /path/to/test_case.exe to test the
   cases on big endianness hosts.

With this patch series, all the tests in [1] can pass.

[1]: under gcc/testsuite/gcc.target/loongarch/vector in the gcc source

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Changes in v2:
- Use QEMU_ALIGNED(128) on the whole VReg struct according to Philippe's
  suggestion.
- Update Fixes: tag in the first patch.
- Link to v1: https://lore.kernel.org/qemu-devel/20260701-loong64-be-v1-0-9c7d65e00697@gmail.com

---
Miao Wang (6):
      target/loongarch: make VReg aligned to 16 bytes
      target/loongarch: Fix offset calculation in vector registers
      target/loongarch: gen_vreplve: Fix offset calculation
      target/loongarch: gen_xvreplve0: Fix elem0 offset calculation
      target/loongarch: do_vldrepl_vl: Fix endianness when reading from guest memory
      target/loongarch: vstelm: Fix reading from vector registers

 target/loongarch/cpu.h                          |  2 +-
 target/loongarch/tcg/insn_trans/trans_vec.c.inc | 39 +++++++++++++------------
 target/loongarch/tcg/translate.c                |  6 ++--
 3 files changed, 25 insertions(+), 22 deletions(-)
---
base-commit: 30e8a06b64aa58a3990ba39cb5d09531e7d265e0
change-id: 20260701-loong64-be-adf8a15675f1

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

