From: Joel Granados <j.granados@samsung.com>
Date: Thu, 28 Sep 2023 15:21:28 +0200
Subject: [PATCH 03/15] xen: Remove now superfluous sentinel element from
 ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230928-jag-sysctl_remove_empty_elem_drivers-v1-3-e59120fca9f9@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=912; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=ui4IGPfTdbR4IGIAbOL4shdoo/J3irZZsIZz3gQ0drk=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlFX3cGe6+E9/0a9eLNoVmJv9uNx1R1TMQIFknp
 t06QGx9crqJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZRV93AAKCRC6l81St5ZB
 T0iCC/4lxYvMPNd56KR9syOhBIjjjL9lOce4FFI9vFCYQ+mZ2iaIno0bBSEmQkEZmez5m10au1S
 g0f8xmfOlU8VaBYmXZwS9WI6d/n6JlMrXlR3plY5Ibf6gPNZgkl8UA4+7SpV6EGGvTeGa4UAkzB
 EXlfYtJNdHkEif74xQjVuQ90sFI3vTWw/qigOxjd4mGmsYhbplpB5NwvVmzV7W0LkH7B6avJXm3
 +HQUyIr5z88PAoFr6xYA+jke9C0E8GfGNyC5xL2BQhlJODuT4otaVMK/c4JGh/LwqHcRCmmBGwY
 9lvf2bY9kysK3mP9qJMxP28IUTW7zlX6v4+ORKyLTUdUSB897zeP+PEecTC8Mq42dUyclAgoUNg
 fLUIUT/Y/nXQcKkPBp8UIZ8Drd829GBO1HjbRjyyO4x2eFGLDe0i3eQPuSUZcYO97lbzOgGicJ8
 XxdRUuA5sTcFBxzCjoIW+6HYKoJz9dRGmUI0TjgcgKEdCLlpYLezYmjA2W+fGyqkVcKT4=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from balloon_table

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/xen/balloon.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/xen/balloon.c b/drivers/xen/balloon.c
index 586a1673459e..091eb2931ac4 100644
--- a/drivers/xen/balloon.c
+++ b/drivers/xen/balloon.c
@@ -93,8 +93,7 @@ static struct ctl_table balloon_table[] = {
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1         = SYSCTL_ZERO,
 		.extra2         = SYSCTL_ONE,
-	},
-	{ }
+	}
 };
 
 #else

-- 
2.30.2

