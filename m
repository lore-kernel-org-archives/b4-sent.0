From: Joel Granados <j.granados@samsung.com>
Date: Thu, 28 Sep 2023 15:21:36 +0200
Subject: [PATCH 11/15] sgi-xp: Remove the now superfluous sentinel element
 from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230928-jag-sysctl_remove_empty_elem_drivers-v1-11-e59120fca9f9@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1399;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=pY2XyujxOt+Rj6u6+44+o009/nkYZtGGPZk9nN2iFyE=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlFX3fe3sdkuVX/cH9+wfjrH5ueAgUPjamrIOH4
 /3zyIkdfAqJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZRV93wAKCRC6l81St5ZB
 TwpRC/4lSj5L+OahMU8+3S1fvTtKAyIY/uKM1bPNHdispZZPQR1Rd3tvqJTptup1mzRuFuO8L1m
 8PJXRwGmMWlfPnW6wWYP/M4Aqq1CITeSckvnMuyUa9IAlZg0a3oKSGu5yX6zSvvAQ0+k7mBAb3y
 UBqDMmlaWuIsDoJskRRHROj9+KwmhMmsEKZWwN5UGxnjSX57Ws5oYdteVXY5AI8Zp7Hy8Tx0heX
 FCndhRyQrnj2jq8I3cC94HaHBQ+r/FbCmV0KJSg5xqjdEy9VmQiEja6TCN2IAUta6kgV5r3iSsz
 uRL2Spqp9oaZW9r25KtgCboTiH5fnCIkTB16pgKJEydjH49JsnKqmlAleVwBd/WjEU86E4be+/t
 V9Kx7iqRDYUo2aZWNOMBizEJlyYBMYHFFIiSdMNx4xMMW78VnCfWmHYPolywQlOL/IO7kdASIva
 qz9zA7cr0tjD3lcLzXnQuXIHAhNUbhz37de0+vmc7TtbbfZaFsJe0s2ItUEMGxrc4UUuo=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from xpc_sys_xpc_hb and xpc_sys_xpc

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/misc/sgi-xp/xpc_main.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/misc/sgi-xp/xpc_main.c b/drivers/misc/sgi-xp/xpc_main.c
index 6da509d692bb..c898092ff3ac 100644
--- a/drivers/misc/sgi-xp/xpc_main.c
+++ b/drivers/misc/sgi-xp/xpc_main.c
@@ -109,8 +109,7 @@ static struct ctl_table xpc_sys_xpc_hb[] = {
 	 .mode = 0644,
 	 .proc_handler = proc_dointvec_minmax,
 	 .extra1 = &xpc_hb_check_min_interval,
-	 .extra2 = &xpc_hb_check_max_interval},
-	{}
+	 .extra2 = &xpc_hb_check_max_interval}
 };
 static struct ctl_table xpc_sys_xpc[] = {
 	{
@@ -120,8 +119,7 @@ static struct ctl_table xpc_sys_xpc[] = {
 	 .mode = 0644,
 	 .proc_handler = proc_dointvec_minmax,
 	 .extra1 = &xpc_disengage_min_timelimit,
-	 .extra2 = &xpc_disengage_max_timelimit},
-	{}
+	 .extra2 = &xpc_disengage_max_timelimit}
 };
 
 static struct ctl_table_header *xpc_sysctl;

-- 
2.30.2

