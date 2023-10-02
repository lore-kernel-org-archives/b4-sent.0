From: Joel Granados <j.granados@samsung.com>
Date: Mon, 02 Oct 2023 10:55:29 +0200
Subject: [PATCH v2 12/15] fw loader: Remove the now superfluous sentinel
 element from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231002-jag-sysctl_remove_empty_elem_drivers-v2-12-02dd0d46f71e@samsung.com>
References: <20231002-jag-sysctl_remove_empty_elem_drivers-v2-0-02dd0d46f71e@samsung.com>
In-Reply-To: <20231002-jag-sysctl_remove_empty_elem_drivers-v2-0-02dd0d46f71e@samsung.com>
To: Luis Chamberlain <mcgrof@kernel.org>, willy@infradead.org, 
 josh@joshtriplett.org, Kees Cook <keescook@chromium.org>, 
 Phillip Potter <phil@philpotter.co.uk>, 
 Clemens Ladisch <clemens@ladisch.de>, Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Juergen Gross <jgross@suse.com>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Oleksandr Tyshchenko <oleksandr_tyshchenko@epam.com>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 "James E.J. Bottomley" <jejb@linux.ibm.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>, 
 Doug Gilbert <dgilbert@interlog.com>, 
 Sudip Mukherjee <sudipm.mukherjee@gmail.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>, 
 Corey Minyard <minyard@acm.org>, Theodore Ts'o <tytso@mit.edu>, 
 "Jason A. Donenfeld" <Jason@zx2c4.com>, David Ahern <dsahern@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Robin Holt <robinmholt@gmail.com>, Steve Wahl <steve.wahl@hpe.com>, 
 Russ Weight <russell.h.weight@intel.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Song Liu <song@kernel.org>, 
 "K. Y. Srinivasan" <kys@microsoft.com>, 
 Haiyang Zhang <haiyangz@microsoft.com>, Wei Liu <wei.liu@kernel.org>, 
 Dexuan Cui <decui@microsoft.com>, Jani Nikula <jani.nikula@linux.intel.com>, 
 Joonas Lahtinen <joonas.lahtinen@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, 
 Tvrtko Ursulin <tvrtko.ursulin@linux.intel.com>, 
 David Airlie <airlied@gmail.com>, Daniel Vetter <daniel@ffwll.ch>
Cc: Joel Granados <j.granados@samsung.com>, linux-kernel@vger.kernel.org, 
 xen-devel@lists.xenproject.org, linux-serial@vger.kernel.org, 
 linux-scsi@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-rdma@vger.kernel.org, openipmi-developer@lists.sourceforge.net, 
 netdev@vger.kernel.org, linux-raid@vger.kernel.org, 
 linux-hyperv@vger.kernel.org, intel-gfx@lists.freedesktop.org, 
 dri-devel@lists.freedesktop.org
X-Mailer: b4 0.13-dev-86aa5
X-Developer-Signature: v=1; a=openpgp-sha256; l=1030;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=dSbsqoYM5F0forI6JAxGBllYsHihbal0Nnr9OSk3MCA=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlGoV/KvOoFfWIcmAF/sCqbEzd0ciPPa7ANRQeV
 5eLgFZ3QDOJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZRqFfwAKCRC6l81St5ZB
 T2T1C/0Ue0/pX8RJDJSDBCMCjQ3HVnnkiI6/qCOH0fnL8+CWShqnWrkdXO6K5PzvyZvto0MaV1O
 qwtKHF0/he5rQjfT19MmMeap2SqXGkznWmnHlVdYtjAcu+eKD7lgElb+2YoOSxzCgrp66NaIHCT
 Rfn9REm0zsNr40oIeungH2jJmzpq48UW91InfOQrc8fNEs7gvVBWFN8x5lsPbgIfzkO0O9Sne0t
 o3E8YDJU+2PoW4qWEeuUOmAVROIwT110ScNs32qOQ+hWxeSXnH5vPTVt651tV9nJinTWPuPoNo8
 GklO6k76kbbl3rN3a4pHNPp5JUfxThANZaFjTs4M54UNA6XL/KY4YSE9kXWGJrE4tWHAMbXYX8M
 1wY9+Tla39Vmi6M2EY0kVNR6xj+LTfD8Qz0P5E2FqXUCFRuwdg5vabCaSNTAdr1FH077BSkS4Z3
 sTt6P68liUw7QyehRCrWLRyiEE4yxcGT9ADxewgJ9bZe1CfP0Y8NhVrZg6/OlaRWYBziM=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from firmware_config_table

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/base/firmware_loader/fallback_table.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/base/firmware_loader/fallback_table.c b/drivers/base/firmware_loader/fallback_table.c
index e5ac098d0742..8432ab2c3b3c 100644
--- a/drivers/base/firmware_loader/fallback_table.c
+++ b/drivers/base/firmware_loader/fallback_table.c
@@ -44,7 +44,6 @@ static struct ctl_table firmware_config_table[] = {
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
 	},
-	{ }
 };
 
 static struct ctl_table_header *firmware_config_sysct_table_header;

-- 
2.30.2

