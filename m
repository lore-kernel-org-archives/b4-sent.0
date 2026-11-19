From: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
Date: Thu, 19 Nov 2026 20:36:51 +0200
Subject: [PATCH] ACPI: APEI: GHES: Poll error sources at their poll
 interval
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-acpi-ghes-poll-interval-v1-1-6f45cc65fd62@ahmedabdelfattah.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDvQicWaXqW4iHHUkRBDxkpBv
 HvTdvkW/x+gnIUVHtUBmXdRWWMBXSrws4sTowzFYK6mISKLzifBaWbFtIaAEjfOuwvY342ltr4
 N1tVQ6pR5lPfv/Oz+1le/sN++OzjPD1CNW/97AAAA
X-Change-ID: 20261119-acpi-ghes-poll-interval-b7291834d9a3
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, Borislav Petkov <bp@alien8.de>, 
 Hanjun Guo <guohanjun@huawei.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Shuai Xue <xueshuai@linux.alibaba.com>, Len Brown <lenb@kernel.org>, 
 Ying Huang <huang.ying.caritas@gmail.com>, Andi Kleen <ak@linux.intel.com>
Cc: linux-acpi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795113411; l=2604;
 i=me@ahmedabdelfattah.dev; s=20261106; h=from:subject:message-id;
 bh=b0r7uAsefW4rVRodqftRqt01KuYseuhB6b4wZW5DsI0=;
 b=7OeOLkqnaiisgRhsJRFMAxD2RZOD5klGHMbhOVzIgcqVOe3WSJrNsz+Rl9honXUPN9vy3ZXh0
 f3pkdBlhqU6AfYOGiilsbOa0ms60LZVhpRENZ8NoXPgebQSrMXSSs8v
X-Developer-Key: i=me@ahmedabdelfattah.dev; a=ed25519;
 pk=DHEHKU4PddrkJ/iYMZpwyyXsFyIQ6ySjTttKLrt9YqI=
X-Endpoint-Received: by B4 Relay for me@ahmedabdelfattah.dev/20261106 with auth_id=1438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ghes_add_timer() passes an absolute time to round_jiffies_relative(),
which takes a delay:

	expire = jiffies + msecs_to_jiffies(g->notify.poll_interval);
	ghes->timer.expires = round_jiffies_relative(expire);

round_jiffies_relative(j) rounds jiffies + j to a whole second and
subtracts jiffies again, so what gets rounded here is 2 * jiffies plus
the interval, and the timer fires up to a second away from the Poll
Interval in the HEST. With a 1000 ms interval, on some boots the polls
come every 1.5 s on average, for seconds or for minutes, and the rest
of the time they are anywhere from 0.75 s to 1.95 s apart. A 250 ms
source settles at one poll a second.

Rounding the delay instead would still move every interval that is not
a whole number of seconds; a 250 ms source would still be polled once a
second. Drop the rounding and use the interval as it is.

Fixes: 81e88fdc432a ("ACPI, APEI, Generic Hardware Error Source POLL/IRQ/NMI notification type support")
Signed-off-by: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
---
I found this while timing a polled GHES in a QEMU guest, with a HEST
built for the test (one polled GHESv2) and given to the guest as an
extra ACPI table.

Tested on v7.4-rc3+ (4405c18c95d2) at HZ=300, tracing ghes_poll_func()
with a kprobe. With a 1000 ms Poll Interval and without the patch, the
intervals on three 10-minute boots ranged from 0.77 s to 1.95 s: one
boot averaged 1.5 s for its first two minutes, and the others
alternated between 280 and 320 jiffies, and between 240 and 360. With
the patch, every interval on three 3-minute boots was 304 jiffies
(1.013 s). With a 250 ms Poll Interval, the polls settled at about one
a second within the first minute without the patch; with it they come
every 80 jiffies (267 ms). The extra 4 and 5 jiffies are the timer
wheel's granularity at those timeouts.
---
 drivers/acpi/apei/ghes.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/acpi/apei/ghes.c b/drivers/acpi/apei/ghes.c
index 5d888c82efea..92d54c6b209a 100644
--- a/drivers/acpi/apei/ghes.c
+++ b/drivers/acpi/apei/ghes.c
@@ -1276,7 +1276,7 @@ static void ghes_add_timer(struct ghes *ghes)
 		return;
 	}
 	expire = jiffies + msecs_to_jiffies(g->notify.poll_interval);
-	ghes->timer.expires = round_jiffies_relative(expire);
+	ghes->timer.expires = expire;
 	add_timer(&ghes->timer);
 }
 

---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261119-acpi-ghes-poll-interval-b7291834d9a3

Best regards,
--  
Ahmed Abdelfattah <me@ahmedabdelfattah.dev>

