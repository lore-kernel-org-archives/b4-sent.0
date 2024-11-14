From: Stephen Horvath <s.horvath@outlook.com.au>
Subject: [PATCH 0/6] decode-dimms: Implement DDR5 decoding
Date: Thu, 14 Nov 2024 16:37:34 +1000
Message-Id: <20241114-decode-ddr5-v1-0-0ed2db8ef30f@outlook.com.au>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK6aNWcC/x3MQQqAIBBA0avIrBNUNKSrRAtzppqNhkIE4t2Tl
 m/xf4NKhanCIhoUerhyTgN6EhCvkE6SjMNglLFqNk4ixYwkEYuTuw/BOuu8NgSjuAsd/P63dev
 9A1wdAKhdAAAA
X-Change-ID: 20240625-decode-ddr5-b8aa4545812e
To: linux-i2c@vger.kernel.org
Cc: Jean Delvare <jdelvare@suse.de>, 
 Stephen Horvath <s.horvath@outlook.com.au>, 
 Guenter Roeck <linux@roeck-us.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1295;
 i=s.horvath@outlook.com.au; s=2024-05-10; h=from:subject:message-id;
 bh=yjwiqCS+mcyDBmeLd00KtGZJyJ/qzKMlwHe28yYIm4k=;
 b=owEBbQKS/ZANAwAKAYC8XiInGJ2jAcsmYgBnNZtvHWZ/Xc7F8uUfAq90j546x8z99urE1xw8E
 +eko9CbBreJAjMEAAEKAB0WIQTIAeBGYgifSxYwNMiAvF4iJxidowUCZzWbbwAKCRCAvF4iJxid
 o2PnEACJSusba7fsL6vQ0alw9MYjvWfDrKd3Xr3KiXiercQ48T/+9x+CGBAhpDaSQ/nT1YLJpca
 KtC4HX/x/XjwuayBSsBZxMI4vnpSI6y7ve+lmWejiw0s6E9OGe+qvFpSAgjt/Hh464xZn8AnIS6
 INLlXRywsloPNZ9mQrVhykDKUxXTJoxTY95UNTd4wKebcCNxiPony2/VBcemQvb2twv7L18J3Ax
 nLkdVjGr98vw2NsyK4PMC29AscFTBx5hrZTi6OH80F/15qb3npV9uPWlxjYOjdNGShXN6XxTbT8
 nHxTvuAyFK8f+Ya4cYLwiDC7XFy++6SZTi2qfcYfpartdNds0nN5NRJ/29tfOAvSZwHL60bbwYK
 R0DUWjlLp3NokqkrwQHBiINt7AxXYQAbVgIjb6ivfFMWT78uZDtpXeIZ38D32WvmbKT/LtCHtPI
 dB6AvquS6Qfk8KYzE/vp1Z6yJWpY/P9XU1feFvYyoR1T6L70Bza2BlTZGgNWJRpQdaZxikK0cBn
 5uYUvnqnAc+KH+ARGcoBeJaPH4JK46CYQw64Ll18A9L2pSw5lpr+CwmfP+71GP+OstZqna0JSBc
 9wXd5unG853hEochkcGF5HtMPLKvj35VhmcE+tP4R8KXI4ShOaoSr+p6dW0YShOV4lw7pDH34+Y
 zx+keMm1DXlbdUw==
X-Developer-Key: i=s.horvath@outlook.com.au; a=openpgp;
 fpr=C801E04662089F4B163034C880BC5E2227189DA3
X-Endpoint-Received: by B4 Relay for s.horvath@outlook.com.au/2024-05-10 with auth_id=277
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi, this series of patches adds DDR5 support to decode-dimms.

I'm not too experienced with perl or the JEDEC specs, so there's probably
going to be some questionable choices here, but I'd love to hear
feedback.

The first 4 patches (1, 2, 3, 4) add the essential information to
decode-dimms.

The next 2 patches (5, 6) haven't really been tested on hardware
implementations so I'm happy for them to be dropped if they're not
useful.

I also wrote these a few months ago, but wasn't sure if I'd be free
enough for any revisions at the time.

Signed-off-by: Stephen Horvath <s.horvath@outlook.com.au>
---
Stephen Horvath (6):
      decode-dimms: Implement DDR5 checksum parsing
      decode-dimms: Decode DDR5 Manufacturer Data
      decode-dimms: Decode timings and other data for DDR5
      decode-dimms: Decode DDR5 common module information
      decode-dimms: Add basic decoding of type specific information for DDR5
      decode-dimms: Decode DDR5 error log

 eeprom/decode-dimms | 517 +++++++++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 513 insertions(+), 4 deletions(-)
---
base-commit: cd435c853bc9df0058620a471d4191c7de27a2f9
change-id: 20240625-decode-ddr5-b8aa4545812e

Best regards,
-- 
Stephen Horvath <s.horvath@outlook.com.au>

