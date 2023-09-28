From: Joel Granados <j.granados@samsung.com>
Date: Thu, 28 Sep 2023 15:21:38 +0200
Subject: [PATCH 13/15] raid: Remove now superfluous sentinel element from
 ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230928-jag-sysctl_remove_empty_elem_drivers-v1-13-e59120fca9f9@samsung.com>
References: <20230928-jag-sysctl_remove_empty_elem_drivers-v1-0-e59120fca9f9@samsung.com>
In-Reply-To: <20230928-jag-sysctl_remove_empty_elem_drivers-v1-0-e59120fca9f9@samsung.com>
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
Cc: linux-kernel@vger.kernel.org, xen-devel@lists.xenproject.org, 
 linux-serial@vger.kernel.org, linux-scsi@vger.kernel.org, 
 linuxppc-dev@lists.ozlabs.org, linux-rdma@vger.kernel.org, 
 openipmi-developer@lists.sourceforge.net, netdev@vger.kernel.org, 
 linux-raid@vger.kernel.org, linux-hyperv@vger.kernel.org, 
 intel-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13-dev-86aa5
X-Developer-Signature: v=1; a=openpgp-sha256; l=881; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=hLoUxHXjHICsfJhbjVPlPY534xjBTCrGFUyV0qQFO8k=;
 b=owEB7AET/pANAwAKAbqXzVK3lkFPAcsmYgBlFX3fSmb3JiEBomhDsQ0pRhV92J1BiKariV8CH
 I/W/L1q3F+JAbIEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZRV93wAKCRC6l81St5ZB
 T8aLC/jP8MCZa3PEhuvknQGR+TNEMb9/sNQf49cF1k/BAyzDsFzY66dheGN5WfDfw9gFPH1BAGC
 mYDHGZ/Ef83bVTjOKxWIr5FY1xZPPiq8Lj0IOUY885EE0Vqta+zhznwJy48L+DavP+QTdcdzNGr
 /SjfAg1wQH7UoWdImUsYYFEZwFYdTasgOIq+kHYD1dVl5/7YQ48ksc/ZBUPKcOZTnbASa2XLJ6U
 8eZSJDcHZNJFf40edYxbXObiufbuPYN7qxohVYR8Dss/si8enpUhlp2t4KSgpZoXixNFVdhqTfc
 lXP1vgHjnT6dLILhSOYJBI/nvGtjo2UiIbRio9vQ1bdy6IbVkv3oytkBjNrblyOcP2EGiM2SbL2
 xiSaTb8iKFmbrr4OP5Ub4xjOTfInkaQjhKuLLcsfJFTqkEpjbjT88xxGZiSKrJnKK5n4vj2tTgw
 CYz/Ud2OnEk44McFYHvFQhN+Kfn87BbWv6vLXMouD4AmlbqVVp4Ri7xfLqVqEIVrBvjg==
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from raid_table

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/md/md.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/md/md.c b/drivers/md/md.c
index a104a025084d..3866d8f754a0 100644
--- a/drivers/md/md.c
+++ b/drivers/md/md.c
@@ -304,8 +304,7 @@ static struct ctl_table raid_table[] = {
 		.maxlen		= sizeof(int),
 		.mode		= S_IRUGO|S_IWUSR,
 		.proc_handler	= proc_dointvec,
-	},
-	{ }
+	}
 };
 
 static int start_readonly;

-- 
2.30.2

