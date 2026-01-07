From: Sam Day <me@samcday.com>
Subject: [PATCH 0/2] usb: gadget: f_fs: DMA-BUF fixes
Date: Thu, 08 Jan 2026 08:30:19 +1000
Message-Id: <20260108-ffs-dmabuf-ioctl-fix-v1-0-e51633891a81@samcday.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDQ0MT3bS0Yt2U3MSk0jTdzPzkkhzdtMwKXSNzIxNLc0MLozQLMyWg1oK
 iVKAw2Njo2NpaAN0/RwNmAAAA
X-Change-ID: 20251114-ffs-dmabuf-ioctl-fix-272497182f86
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sam Day <me@samcday.com>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767825022; l=960;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=NpEMi+FFcLqCy+VebtjlU5KccAtE1btumT4cEIVROu0=;
 b=225R0QWiOaY4AzMFirxupqQeTXM+RWuCMCHsZJOaHWooi5dyVMGKeFJxvG2f4baryYjxMgELG
 ZNMYJpt/2AxCNqn8nRsR279l5Uy/gZtpyPpLbr6Ux3wNU97buREp99l
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I recently started kicking the tires on DMA-BUF support in FunctionFS.
In the process, I found a couple of issues that are fixed in this
series.

One issue is a minor bug in how the ioctl handler treats invalid calls.
The other is more serious and breaks DMA transfers on systems with a
tenacious SMMU.

I created a fairly minimal reproducer of the DMA issue in this gist, to
assist in testing:

https://gist.github.com/samcday/d23aaf95be678bcdd1dd62b4b79861ea

Tested on:
 - Pixel 3a
 - OnePlus 6T

Signed-off-by: Sam Day <me@samcday.com>
---
Sam Day (2):
      usb: gadget: f_fs: Fix ioctl error handling
      usb: gadget: f_fs: fix DMA-BUF OUT queues

 drivers/usb/gadget/function/f_fs.c | 24 +++++++++---------------
 1 file changed, 9 insertions(+), 15 deletions(-)
---
base-commit: f0b9d8eb98dfee8d00419aa07543bdc2c1a44fb1
change-id: 20251114-ffs-dmabuf-ioctl-fix-272497182f86

Best regards,
-- 
Sam Day <me@samcday.com>

