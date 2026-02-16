From: Kairui Song <kasong@tencent.com>
Subject: [PATCH v4 0/3] mm/swap: hibernate: improve hibernate performance
 with new allocator
Date: Mon, 16 Feb 2026 22:58:01 +0800
Message-Id: <20260216-hibernate-perf-v4-0-1ba9f0bf1ec9@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33M0QqDIBiG4VsJj+fQv8za0e5j7CDtd3kwCxXZi
 O59Fgy2BTt8P/iemQT0FgM5FTPxmGywo8tRHQqih87dkNo+NwEGNQMOdLAKvesi0gm9oUZJ2ZQ
 KFAgg+TR5NPaxgZdr7sGGOPrn5ie+rm9K/FKJU0aNEIgtYi17dY7oNLp41OOdrFiC/wBkQBtot
 BSKVUrugfITqHdAmQFZIQPBWs4r8Q0sy/ICjdPWYDABAAA=
X-Change-ID: 20260212-hibernate-perf-fb7783b2b252
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Barry Song <baohua@kernel.org>, 
 Carsten Grohmann <mail@carstengrohmann.de>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, linux-kernel@vger.kernel.org, 
 "open list:SUSPEND TO RAM" <linux-pm@vger.kernel.org>, 
 Carsten Grohmann <carstengrohmann@gmx.de>, Kairui Song <kasong@tencent.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771253885; l=2863;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=sO7TBYofqYSM2bgeL92RYGu50mNH9qEmCpadIybs00Y=;
 b=CpIU6uKntmcDupIJYIVmNkZrat/SPDOFtjFTIqHnuR4BpQdR82jnesJYYScaxY4crDNFtIKs+
 pzIT1VZg+Y9CEOaqZvFVJ7o4WqAzx1ovXKLIf+7wkElkcoOdiDUWyUK
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
Tested-by: Carsten Grohmann <mail@carstengrohmann.de>
Link: https://lore.kernel.org/linux-mm/8b4bdcfa-ce3f-4e23-839f-31367df7c18f@gmx.de/ [1]
---
Changes in v4:
- Reduce indent and improve code comment, as suggested by [ Barry Song ]
- Link to v3: https://lore.kernel.org/r/20260216-hibernate-perf-v3-0-74e025091145@tencent.com

Changes in v3:
- Split the indention change to a standalone patch.
- Update mail address and add Cc stable.
- Link to v2: https://lore.kernel.org/r/20260215-hibernate-perf-v2-0-cf28c75b04b7@tencent.com

Changes in v2:
- Based on mm-unstable, resend using b4's relay to fix mismathed patch content.
- Link to v1: https://lore.kernel.org/r/20260215-hibernate-perf-v1-0-f55ee9ee67db@tencent.com

---
Kairui Song (3):
      mm, swap: speed up hibernation allocation and writeout
      mm, swap: reduce indention for hibernate allocation helper
      mm, swap: merge common convention and simplify allocation helper

 mm/swapfile.c | 92 ++++++++++++++++++++++++++++++++++-------------------------
 1 file changed, 53 insertions(+), 39 deletions(-)
---
base-commit: 53f061047924205138ad9bc315885255f7cc4944
change-id: 20260212-hibernate-perf-fb7783b2b252

Best regards,
-- 
Kairui Song <kasong@tencent.com>

