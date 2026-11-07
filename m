From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:57 -0800
Subject: [PATCH RFC v3 83/88] KVM: selftests: Verify VFIO ioeventfd
 creation for igb device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-83-8484dde66a7e@google.com>
References: <20261106-gmem-alternative-providers-v3-0-8484dde66a7e@google.com>
In-Reply-To: <20261106-gmem-alternative-providers-v3-0-8484dde66a7e@google.com>
To: Alexey Kardashevskiy <aik@amd.com>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 Christian Brauner <brauner@kernel.org>, 
 David Hildenbrand <david@kernel.org>, David Woodhouse <dwmw2@infradead.org>, 
 Fred Griffoul <fgriffo@amazon.co.uk>, 
 Jacob Pan <jacob.pan@linux.microsoft.com>, Jianxiong Gao <jxgao@google.com>, 
 John Starks <John.Starks@microsoft.com>, 
 Michael Roth <michael.roth@amd.com>, Paolo Bonzini <pbonzini@redhat.com>, 
 Samiullah Khawaja <skhawaja@google.com>, 
 Sean Christopherson <seanjc@google.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Tarun Sahu <tarunsahu@google.com>, Vishal Annapurve <vannapurve@google.com>, 
 Xu Yilun <yilun.xu@linux.intel.com>, Fuad Tabba <fuad.tabba@linux.dev>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=2410;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=lOTB0T1ZgH2qBwxbzF1p5KVxU2nrnnE76xPmcwyhgYk=;
 b=dWWgKLHu4omBOrcbWgEzhyA8WgLPlocfMYQX0wM811XEqldFlmfdRwW/DSH6jtFRb5JzYUcHE
 Z8Q/wpLQ65VBYUKMm9/i2vELQblt1W1Vak0UmJun4RPZLtCa7JjWqVb
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a subtest to verify ioeventfd registration and unregistration on
the bound Intel 82576 device.

Allocate an eventfd and configure a VFIO_DEVICE_IOEVENTFD ioctl targeting
the scratch receive address low (RAL0) register in BAR0 with 4-byte width
and a test trigger value.

Assert that in direct mode registration succeeds and that unregistration
(passing fd = -1 with matching register criteria) succeeds cleanly.
In guest_memfd mode, verify that ioeventfd registration is rejected with
-EOPNOTSUPP.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 .../selftests/kvm/x86/guest_memfd_vfio_test.c      | 39 ++++++++++++++++++++++
 1 file changed, 39 insertions(+)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
index 46d325228bda3..dde249571ebc4 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
@@ -10,6 +10,7 @@
 #include <stdlib.h>
 #include <string.h>
 #include <unistd.h>
+#include <sys/eventfd.h>
 #include <sys/ioctl.h>
 #include <sys/mman.h>
 #include <sys/types.h>
@@ -725,4 +726,42 @@ TEST_F(guest_memfd_vfio, dmabuf_creation)
 	free(feat);
 }
 
+TEST_F(guest_memfd_vfio, ioeventfd_creation)
+{
+	struct vfio_device_ioeventfd ioeventfd = {};
+	struct vfio_region_info bar0_info = {};
+	int ret;
+	int efd;
+
+	bar0_info.argsz = sizeof(bar0_info);
+	bar0_info.index = VFIO_PCI_BAR0_REGION_INDEX;
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_GET_REGION_INFO, &bar0_info);
+	ASSERT_EQ(0, ret);
+
+	efd = eventfd(0, EFD_CLOEXEC);
+	ASSERT_GE(efd, 0);
+
+	/* Register ioeventfd on BAR0 targeting RAL0 with 4-byte width */
+	ioeventfd.argsz = sizeof(ioeventfd);
+	ioeventfd.flags = VFIO_DEVICE_IOEVENTFD_32;
+	ioeventfd.offset = bar0_info.offset + E1000_RAL0;
+	ioeventfd.data = 0xdeadbeef;
+	ioeventfd.fd = efd;
+
+	ret = ioctl(self->vfio_fd, VFIO_DEVICE_IOEVENTFD, &ioeventfd);
+	if (variant->use_gmem) {
+		ASSERT_LT(ret, 0);
+		ASSERT_EQ(EOPNOTSUPP, errno);
+	} else {
+		ASSERT_EQ(0, ret);
+
+		/* Unregister ioeventfd by passing fd = -1 with identical match criteria */
+		ioeventfd.fd = -1;
+		ret = ioctl(self->vfio_fd, VFIO_DEVICE_IOEVENTFD, &ioeventfd);
+		ASSERT_EQ(0, ret);
+	}
+
+	close(efd);
+}
+
 TEST_HARNESS_MAIN

-- 
2.56.0.455.g6c5a503b38-goog

