From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:19 -0800
Subject: [PATCH RFC v3 45/88] samples/kvm: Disallow MP_SET_READONLY after
 attach
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-45-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=1622;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=W6hpgZ/SuWeulozFQ+D1CrfcagL7NIynEtQGb/opNZw=;
 b=ILyPeR8Z4qzwmTsH228I3CTu1pFhQQ5MWMIByYFJpNmOGFiP/sRffFefkPZJvJJmQLFRCWCMe
 r5kLMeQnZa7CLlcRG/TOCMgsnzmWL3Yhl8aE192+9z9TDbTji6SwO+6
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Once a provider file is attached to guest_memfd, its physical attributes
must remain constant throughout its lifetime.

Disallow changing page read-only state via MP_SET_READONLY if the provider
file is currently attached to a guest_memfd inode, returning -EBUSY.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 samples/kvm/memory_provider.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/samples/kvm/memory_provider.c b/samples/kvm/memory_provider.c
index 6f86e3e3262e3..168c1d90edacd 100644
--- a/samples/kvm/memory_provider.c
+++ b/samples/kvm/memory_provider.c
@@ -58,17 +58,23 @@ static int mp_range(struct mp_info *info, u64 offset, u64 len,
 	return 0;
 }
 
-static void mp_set_readonly(struct mp_info *info, unsigned long start,
+static int mp_set_readonly(struct mp_info *info, unsigned long start,
 			    unsigned long end, bool readonly)
 {
 	mutex_lock(&info->lock);
 
+	if (info->gmem_inode) {
+		mutex_unlock(&info->lock);
+		return -EBUSY;
+	}
+
 	if (readonly)
 		bitmap_set(info->readonly, start, end - start);
 	else
 		bitmap_clear(info->readonly, start, end - start);
 
 	mutex_unlock(&info->lock);
+	return 0;
 }
 
 static void mp_set_present(struct mp_info *info, unsigned long start,
@@ -123,7 +129,7 @@ static long mp_file_set_readonly(struct mp_info *info, void __user *uarg)
 
 	ret = mp_range(info, sr.offset, sr.len, &start, &end);
 	if (!ret)
-		mp_set_readonly(info, start, end, sr.value);
+		ret = mp_set_readonly(info, start, end, sr.value);
 
 	return ret;
 }

-- 
2.56.0.455.g6c5a503b38-goog

