From: Kairui Song <kasong@tencent.com>
Subject: [PATCH v2 0/2] mm/swap: hibernate: improve hibernate performance
 with new allocator
Date: Sun, 15 Feb 2026 19:15:04 +0800
Message-Id: <20260215-hibernate-perf-v2-0-cf28c75b04b7@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13MwQ6CMBCE4Vche7YG1pSqJ9/DcKBlKnuwkLYhG
 sK7W0m8ePwnmW+lhChIdK1WilgkyRRK8KEiN/bhASVDaeKa25obVqNYxNBnqBnRK2+NOZ8sW9Z
 M5TRHeHnt4L0rPUrKU3zv/tJ81x+l/6mlUbXyWgMXoDWDvWUEh5CPbnpSt23bB9Yf3cauAAAA
X-Change-ID: 20260212-hibernate-perf-fb7783b2b252
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Barry Song <baohua@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Carsten Grohmann <carstengrohmann@gmx.de>, linux-kernel@vger.kernel.org, 
 "open list:SUSPEND TO RAM" <linux-pm@vger.kernel.org>, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771154107; l=2398;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=NQIjZ4ioUQRkgBsK3tTxiXoZE9AA6RuocC+q3Uk/4Y0=;
 b=S3NiucafmUUST/nkOt+IvADfvetNDt1JzSV8IQDhzqNXwofm3wrAiMiPz3Uh43VWuydX61Fvs
 qflPpuuZ78iCwE76Uq1SqsbxlVzII2pvjz+ZZUo3EfmkLMiXfTvC13J
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The new swap allocator didn't provide a high-performance allocation
method for hibernate, and just left it using the easy slow path. As a
result, hibernate performance is quite bad on some devices

Fix it by implementing hibernate support for the fast allocation path.

This regression seems only happen with SSD devices with poor 4k
performance. I've tested on several different NVME and SSD setups, the
performance diff is tiny on them, but testing on a Samsung SSD 830
Series (SATA II, 3.0 Gbps) showed a big difference [1]:

Test result with Samsung SSD 830 Series (SATA II, 3.0 Gbps) thanks
to Carsten Grohmann [1]:
6.19:               324 seconds
After this series:  35 seconds

Test result with SAMSUNG MZ7LH480HAHQ-00005 (SATA 3.2, 6.0 Gb/s):
Before 0ff67f990bd4: Wrote 2230700 kbytes in 4.47 seconds (499.03 MB/s)
After 0ff67f990bd4: Wrote 2215472 kbytes in 4.44 seconds (498.98 MB/s)
After this series: Wrote 2038748 kbytes in 4.04 seconds (504.64 MB/s)

Test result with Memblaze P5910DT0384M00:
Before 0ff67f990bd4: Wrote 2222772 kbytes in 0.84 seconds (2646.15 MB/s)
After 0ff67f990bd4: Wrote 2224184 kbytes in 0.90 seconds (2471.31 MB/s)
After this series: Wrote 1559088 kbytes in 0.55 seconds (2834.70 MB/s)

The performance is almost the same for blazing fast SSDs, but for some
SSDs, the performance is several times better.

Patch 1 improves the hibernate performance by using the fast path, and
patch 2 cleans up the code a bit since there are now multiple fast path
users using similar conventions.

Signed-off-by: Kairui Song <kasong@tencent.com>
Tested-by: Carsten Grohmann <carstengrohmann@gmx.de>
Link: https://lore.kernel.org/linux-mm/8b4bdcfa-ce3f-4e23-839f-31367df7c18f@gmx.de/ [1]
---
Changes in v2:
- Based on mm-unstable, resend using b4's relay to fix mismathed patch content.
- Link to v1: https://lore.kernel.org/r/20260215-hibernate-perf-v1-0-f55ee9ee67db@tencent.com

---
Kairui Song (2):
      mm, swap: speed up hibernation allocation and writeout
      mm, swap: merge common convention and simplify allocation helper

 mm/swapfile.c | 56 ++++++++++++++++++++++++++------------------------------
 1 file changed, 26 insertions(+), 30 deletions(-)
---
base-commit: 53f061047924205138ad9bc315885255f7cc4944
change-id: 20260212-hibernate-perf-fb7783b2b252

Best regards,
-- 
Kairui Song <kasong@tencent.com>

