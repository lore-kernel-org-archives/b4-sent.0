From: Joel Granados <j.granados@samsung.com>
Date: Thu, 28 Sep 2023 15:21:35 +0200
Subject: [PATCH 10/15] vrf: Remove the now superfluous sentinel element
 from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230928-jag-sysctl_remove_empty_elem_drivers-v1-10-e59120fca9f9@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=957; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=1NLC9qP1CY5hbDPyr23yN2zoH2+i6NGjxa91ihvztxA=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlFX3efmxA5MIacGiPYUJqzMHLsUucZXUhKmZvp
 uwNl2wpIdyJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZRV93gAKCRC6l81St5ZB
 T7zVC/9nccm8Jt9uhH7oQGv/uUE1TUHdyD8riQXjy6Q7siM8V6fZZKtqQAuVbgk+dQ+XYCY0MXU
 +gofOFghmvbuZW33bSsn6BpCMPsZitmR2AIrJz40JNmDes9atMglKzaw6YK2sktVhAl5vRjsBF6
 C5J/9HUHSFTD8MEiz/KG9qmfVDtOhZJrKQgG/eDxaK/tTOWULGYjcrTRsBdqVkhYUwiQyEmiisu
 obKNXMg1SnhtJyaW6u1yDjXdEuCYd7wdKEyFxJI/TVAsD80Usfi+gJ22UC1YiyxBWVYbaLTcm3/
 zXaEujj/bV6H7Mg+H3VBldoOzwUvs2J/KXMTzFHPGN3CideOlJrNCrkFP8axi7opC2TPD+ep4pW
 0zw45g4ZcDDdEZ7ttDDSQIcb3A6YNO2mXHNC8l8Op9uQPlfVSgcF0E0Tm7cxZd0lrEy+neUKS8q
 GUMrJtSPCvRNPD4xWGcwfpGrX5UX9Vuuit+whdxcOw2k8YWghpbrglRWCjHk82JtuA8a4=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from vrf_table

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/net/vrf.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/net/vrf.c b/drivers/net/vrf.c
index a3408e4e1491..94eed8708467 100644
--- a/drivers/net/vrf.c
+++ b/drivers/net/vrf.c
@@ -1962,8 +1962,7 @@ static const struct ctl_table vrf_table[] = {
 		.proc_handler	= vrf_shared_table_handler,
 		/* set by the vrf_netns_init */
 		.extra1		= NULL,
-	},
-	{ },
+	}
 };
 
 static int vrf_netns_init_sysctl(struct net *net, struct netns_vrf *nn_vrf)

-- 
2.30.2

