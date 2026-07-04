From: Miao Wang <shankerwangmiao@gmail.com>
Date: Sun, 05 Jul 2026 03:50:49 +0800
Subject: [PATCH] qemu-options: Enable the -enable-kvm option for loongarch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260705-add-loong64-kvm-v1-1-aa8b85ecfa32@gmail.com>
X-B4-Tracking: v=1; b=H4sIABhkSWoC/x3MQQqAIBBA0avErBswKYOuEi2qGW2oNBQkiO6et
 HyL/x9IHIUTDNUDkbMkCb6gqStYt9k7RqFi0Eob1asOZyI8QvDOtLjnE0n3Da+GFC8WSnVFtnL
 /x3F63w+8SodGYQAAAA==
X-Change-ID: 20260705-add-loong64-kvm-d271ec6d0ebf
To: qemu-devel@nongnu.org
Cc: Paolo Bonzini <pbonzini@redhat.com>, Song Gao <gaosong@loongson.cn>, 
 Jiaxun Yang <jiaxun.yang@flygoat.com>, b4-sent@feeds.kernel.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=908;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=PNPCtIMkRVK0W0qxTiHLb/6sHgdzlIg+LHyIGQMkZOg=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqSWQdZbln0nBPF/MUEWhAJnBVvj68yui68kwBK
 GJvZ7XYAlaJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCaklkHQAKCRCwMePKe/7Z
 bqDuEACEUUv91y0X4mn0YdQZQHfur01hnPvgiEzLB0f1/7J80m/76pFXdFe3hH3dUZSL/Wwcu/A
 45ktFdGifpq4YIXYhuuQzLI7ZAQ9htk8X3LyMIlx/8VCppdCsbAPr0yGqvmdaStJtxNDPjxApQ4
 ATNAGFmmIiwI4a8BCmyvQX6ZIyqynVtVXOiPSnk7sH8Db/5SqmUlEnxdftVvUJ/icaDj+FUJH7c
 a2wV+qxrCNBbFRxzgGhJBQIREYJvU7H5STL+YziUiSf0k4Deqku7srUoV53C+lbEBfb0t5BJlkr
 xLsxMKjcunwB270wtrC/tDQonP94oSgdj9oltQmUnVydfYw0NNQY36Rpj3VJviTpCY7CrKPRT4g
 ak6LsIERABRsaucVSeWT0ExaEuN+ewwmQccitbMgKccXl7k87yIlp3nORFAAh3i85Fr/PzSspj3
 nmxeW4OVaVTX3r/c0COQk34h+AkRUXVaEHN3uALb0z2Ca/LZPY6OqXrxPcrLIubQOIVs+yvbhgb
 1KhDRutCkkTo0LbJzK+QzNqyjO+XIsO+FOt4QxdQwsfcJXvjtKwjIjuFXO/UoJHWzdZyGh0vcXB
 JFjWwbgmwZCpDIstUM1paIRYXKOxlpQOhlc5vkf9t9lJM8eTNzQ/F9yWvuCCQmH3UN5DmAEyt0g
 xyHQI1CMfJCzN3w==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 qemu-options.hx | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/qemu-options.hx b/qemu-options.hx
index e44b47de68137120da9979fb081d0c108f13179c..c7dbbd01e73367380fcf653fa8d0d18795dde9a7 100644
--- a/qemu-options.hx
+++ b/qemu-options.hx
@@ -5164,7 +5164,7 @@ ERST
 DEF("enable-kvm", 0, QEMU_OPTION_enable_kvm, \
     "-enable-kvm     enable KVM full virtualization support\n",
     QEMU_ARCH_ARM | QEMU_ARCH_I386 | QEMU_ARCH_MIPS | QEMU_ARCH_PPC |
-    QEMU_ARCH_RISCV | QEMU_ARCH_S390X)
+    QEMU_ARCH_RISCV | QEMU_ARCH_S390X | QEMU_ARCH_LOONGARCH)
 SRST
 ``-enable-kvm``
     Enable KVM full virtualization support. This option is only

---
base-commit: 30e8a06b64aa58a3990ba39cb5d09531e7d265e0
change-id: 20260705-add-loong64-kvm-d271ec6d0ebf

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

