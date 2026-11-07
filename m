From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:58 -0800
Subject: [PATCH RFC v3 24/88] samples/kvm: Support querying provider file
 statistics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-24-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=2463;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=EXFH+VGzYxLpiOlUm7+SXlMva0hegPehiKidAH67grc=;
 b=7hVXjaGVJOqfQUrfhjyeyzSTfHIZXZzwulk8Vbz7CGvVDPIUBAJOG2RgnAgqms/2SVLnSXQAW
 lqMSMLCfKWxDFL1pj/KHF5J/ocwGPTJlfOisEvzy/H2N3JF6+G9BW47
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Fred Griffoul <fgriffo@amazon.co.uk>

Support the MP_GET_STATS ioctl on provider files so userspace and selftests
can inspect the total capacity, number of absent pages, and number of
read-only pages of a provider file.

Co-developed-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Fred Griffoul <fgriffo@amazon.co.uk>
---
 samples/kvm/memory_provider.c | 16 ++++++++++++++++
 samples/kvm/memory_provider.h | 10 ++++++++++
 2 files changed, 26 insertions(+)

diff --git a/samples/kvm/memory_provider.c b/samples/kvm/memory_provider.c
index 39aeb1a0b93f6..81ac94ae1a4e9 100644
--- a/samples/kvm/memory_provider.c
+++ b/samples/kvm/memory_provider.c
@@ -81,6 +81,20 @@ static void mp_set_present(struct mp_info *info, unsigned long start,
 	mutex_unlock(&info->lock);
 }
 
+static long mp_get_stats(struct mp_info *info, void __user *uarg)
+{
+	struct mp_stats st = {
+		.size = (u64)info->npages << PAGE_SHIFT,
+	};
+
+	mutex_lock(&info->lock);
+	st.absent_pages = bitmap_weight(info->absent, info->npages);
+	st.readonly_pages = bitmap_weight(info->readonly, info->npages);
+	mutex_unlock(&info->lock);
+
+	return copy_to_user(uarg, &st, sizeof(st)) ? -EFAULT : 0;
+}
+
 static int mp_file_release(struct inode *inode, struct file *file)
 {
 	struct mp_info *info = file->private_data;
@@ -136,6 +150,8 @@ static long mp_file_ioctl(struct file *file, unsigned int cmd,
 	void __user *uarg = (void __user *)arg;
 
 	switch (cmd) {
+	case MP_GET_STATS:
+		return mp_get_stats(info, uarg);
 	case MP_SET_PRESENT:
 		return mp_file_set_present(info, uarg);
 	case MP_SET_READONLY:
diff --git a/samples/kvm/memory_provider.h b/samples/kvm/memory_provider.h
index f3772f57f5bf5..24a201a58e83b 100644
--- a/samples/kvm/memory_provider.h
+++ b/samples/kvm/memory_provider.h
@@ -27,6 +27,16 @@ struct mp_new_file {
 #define MP_NEW_FILE \
 	_IOW(MP_IOCTL_BASE, 5, struct mp_new_file)
 
+/* ioctl on a provider fd: read the file's state, for tests. */
+struct mp_stats {
+	__u64 size;
+	__u64 absent_pages;	/* pages taken away by MP_SET_PRESENT */
+	__u64 readonly_pages;	/* pages marked read-only by MP_SET_READONLY */
+};
+
+#define MP_GET_STATS \
+	_IOR(MP_IOCTL_BASE, 10, struct mp_stats)
+
 /*
  * ioctl on a provider fd: SET_READONLY on [@offset, @offset + @len).
  * @value is the read-only value (1 = read-only, 0 = writable), and @offset

-- 
2.56.0.455.g6c5a503b38-goog

