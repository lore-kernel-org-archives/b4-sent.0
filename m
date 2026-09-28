From: Bernd Schubert <bernd@bsbernd.com>
Date: Mon, 28 Sep 2026 13:02:16 +0200
Subject: [PATCH v2 14/14] Improve documentation for fuse service mount
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260928-mount-service-bound-open-v2-14-0f9f501d05ce@bsbernd.com>
References: <20260928-mount-service-bound-open-v2-0-0f9f501d05ce@bsbernd.com>
In-Reply-To: <20260928-mount-service-bound-open-v2-0-0f9f501d05ce@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, neal@gompa.dev, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=57232; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=r9mx94eDCnGQbk6uD8jnvnghRASkhEvTJc3VLSQAD5s=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLJ2eTpXSn+Il65zucXw1zgz98TrzJtXX72r2fCxwbHA7
 bayl7FrRykLgxgHg6yYIkuXxB7bKf/4ZNW+rr8OM4eVCWQIAxenAExkVRbD//zoB/pnpa7e3bb4
 tNiLctEZEnsyfBXtZLMjfVlZP9l5ZDIy3F4jUMkmH/Jub9xeUbeLc97U7Pa9r8K8x2txpuxvc/N
 j7AA=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 doc/README.service-mount      | 312 +++++++++++++++++++++++++++++
 doc/README.service-mount-dev  | 456 ++++++++++++++++++++++++++++++++++++++++++
 doc/README.service-mount-flow | 201 +++++++++++++++++++
 doc/fuservicemount3.8         | 150 +++++++++++++-
 doc/mainpage.dox              |  13 ++
 doc/mount.fuse3.8             |  18 ++
 6 files changed, 1144 insertions(+), 6 deletions(-)

diff --git a/doc/README.service-mount b/doc/README.service-mount
new file mode 100644
index 000000000000..859db863f3da
--- /dev/null
+++ b/doc/README.service-mount
@@ -0,0 +1,312 @@
+Mounting FUSE filesystems that run as a socket service
+======================================================
+
+This document is for administrators and end users who want to mount a FUSE
+filesystem whose server runs as a sandboxed systemd socket service, rather
+than as a process in the mount caller's own context.
+
+Developers who want to make their FUSE server runnable this way should read
+README.service-mount-dev instead.
+
+
+What a service mount is
+-----------------------
+
+A traditional FUSE filesystem runs as a child of whoever mounts it: it
+inherits that environment, needs mount permission, and can see the caller's
+files. A *service mount* instead keeps the FUSE server running as an
+independent systemd service. When someone mounts the filesystem, a small
+privileged helper (fuservicemount3) connects to the service over a UNIX
+socket, hands it the /dev/fuse device and any backing files it needs, and
+performs the mount on its behalf.
+
+The benefit is isolation. The server can run:
+
+  - as a separate, unprivileged uid/gid (systemd DynamicUser),
+  - with no capabilities at all,
+  - in private mount, network, and pid namespaces,
+  - with a restricted system-call filter,
+
+while still being mountable by an ordinary user. The server never gains mount
+permission and never runs in the caller's environment; the privileged work is
+confined to the fuservicemount3 helper. See example/service_ll@.service for a
+fully locked-down unit.
+
+
+Do I need this?
+---------------
+
+This feature exists for one specific goal: running a FUSE server with strong
+privilege separation, where the server itself is fully unprivileged and
+sandboxed while a separate setuid helper performs the mount. Getting that
+requires the server to be written to the fuse_service_* API (see
+README.service-mount-dev). An existing FUSE program that simply calls
+fuse_main() cannot be mounted this way unmodified: it opens /dev/fuse and
+performs the mount itself, which the sandbox does not allow.
+
+If all you want is to manage an ordinary FUSE filesystem with systemd --
+start/stop, journald logging, cgroup resource limits --
+you do NOT need this feature. Run the filesystem under a plain systemd service
+unit instead, launching it in the foreground so systemd can track it:
+
+    # myfs.service
+    [Service]
+    ExecStart=/usr/bin/myfs ... -f <mountpoint>
+
+systemd-run(1) starts the same thing as a transient unit, without a unit
+file. It passes the command line on as typed, so the filesystem can get any
+number of arguments. A unit file fixes them in its ExecStart= line, and a
+template unit (myfs@.service) takes only one parameter, the instance name.
+Set unit directives with -p:
+
+    sudo systemd-run -p MemoryMax=1G myfs <args> -f <mountpoint>
+
+This also works in the user's own service manager, as long as fusermount3 is
+installed setuid root:
+
+    systemd-run --user -p MemoryMax=1G myfs <args> -f <mountpoint>
+
+That filesystem still mounts the traditional way (through fusermount3) and
+runs in the service's own context; it is not isolated from the mount the way a
+service mount is.
+
+Use a service mount when you specifically want:
+
+  - the filesystem server to run as a separate, unprivileged uid with no
+    mount permission of its own,
+  - it confined to private mount/network/pid namespaces with no capabilities,
+  - the privileged mount work isolated in the fuservicemount3 helper,
+  - on-demand, socket-activated startup.
+
+In short: a plain systemd unit gives you lifecycle management; a service mount
+gives you lifecycle management AND isolation, at the cost of the fuse server
+author adapting the server to the service API.
+
+
+Requirements
+------------
+
+Service mount support is only built when libfuse is configured with systemd
+support:
+
+  - the systemd development headers (libsystemd-dev), and
+  - a known systemd system unit directory.
+
+When both are present, meson defines HAVE_SERVICEMOUNT and builds the
+fuservicemount3 helper. If either is missing, meson prints a warning and the
+feature is left out; mounts then fall back to the traditional path (see
+"Dispatch and fallback" below).
+
+Relevant meson options:
+
+  - service-socket-dir    directory that holds the per-filesystem service
+                          sockets (default: /run/fuse)
+  - service-socket-perms  mode for the socket files (default: 0220)
+  - systemd-system-unit-dir
+                          where to install service/socket units (default:
+                          taken from the systemd pkg-config file)
+
+fuservicemount3 is installed setuid root, just like fusermount3, so that
+unprivileged users can trigger a mount handled by the service. The setuid
+privilege is what lets it perform the mount; it drops back to the real user
+before connecting to the service socket, so the socket's own permissions are
+what decide who may mount. The default 0220 mode is only a starting point --
+set SocketUser=, SocketGroup= and SocketMode= in the .socket unit to grant the
+intended users access (see "Who establishes the connection" below).
+
+
+Installing a service
+--------------------
+
+Each mountable filesystem type is backed by two systemd units, named after the
+filesystem subtype (the part after "fuse." in the mount type). For a subtype
+"myfs":
+
+  - myfs@.service   the sandboxed server (a template, one instance per
+                    connection)
+  - myfs.socket     the listening socket that activates it
+
+The socket listens on a SOCK_SEQPACKET UNIX socket at
+
+  <service-socket-dir>/<subtype>            e.g. /run/fuse/myfs
+
+and is configured with "Accept=yes", so systemd spawns a fresh, isolated
+server instance for every mount request.
+
+The path field (sun_path) of a UNIX socket address holds 108 bytes on Linux,
+so <service-socket-dir>/<subtype> can be at most 107 characters long. The
+default /run/fuse leaves 97 characters for the subtype. If the path is
+longer, mount.fuse3 mounts the traditional way and fuservicemount3 fails with
+"filesystem type name `<subtype>' is too long".
+
+Install the units into the systemd unit directory (usually
+/run/systemd/system or /etc/systemd/system), then:
+
+    systemctl daemon-reload
+    systemctl start myfs.socket
+
+The socket unit can be enabled to start at boot:
+
+    systemctl enable myfs.socket
+
+The example filesystems ship ready-to-adapt units; see
+example/service_ll@.service and example/service_ll.socket(.in).
+
+
+Mounting
+--------
+
+Mount the filesystem with the usual mount(8) syntax, using the type
+"fuse.<subtype>":
+
+    mount -t fuse.myfs <source> <mountpoint> [-o options]
+
+For example:
+
+    mount -t fuse.service_ll /dev/sda /mnt
+
+A block-device-backed filesystem uses "fuseblk.<subtype>" instead.
+
+The same line works from /etc/fstab:
+
+    <source>  <mountpoint>  fuse.myfs  <options>  0 0
+
+The mount is handled by the mount.fuse3 helper, which notices that a service
+socket exists for the type and hands the request to fuservicemount3. Every
+argument except "-t <type>" -- the <source>, the <mountpoint> and the -o
+options -- is forwarded to the running server for parsing.
+
+
+Checking whether a service is available
+---------------------------------------
+
+To test whether a service socket exists for a given filesystem type without
+mounting anything:
+
+    fuservicemount3 -t fuse.myfs --check
+
+It exits 0 if the service socket exists and you may connect to it (write
+permission), non-zero otherwise. systemd starts a server only when
+fuservicemount3 connects, so an existing socket means a mount will get one.
+This relies on RemoveOnStop=yes in the .socket unit; without it, a stopped
+unit leaves a stale socket file behind.
+
+
+Unmounting
+----------
+
+Unmount as you would any FUSE filesystem:
+
+    fusermount3 -u <mountpoint>
+
+or, as a privileged user:
+
+    umount <mountpoint>
+
+
+Dispatch and fallback
+---------------------
+
+When you run "mount -t fuse.myfs ...", the mount.fuse3 helper first checks for
+a service socket for "myfs". The behaviour is:
+
+  - If a socket exists (and no options that are incompatible with service
+    mounts were given), the mount is performed through fuservicemount3 and the
+    running service.
+
+  - If no socket exists or options that are incompatible with service mounts
+    were given, mount.fuse3 transparently falls back to the traditional path:
+    it runs the filesystem server program directly, exactly as it did before
+    service mount support.
+
+So enabling service mount support does not break filesystems that are not set
+up as services; they continue to mount the old way.
+
+A few options force the traditional path and skip the service even when a
+socket is present, because they are meaningless to an already-running,
+isolated server (for example passing a pre-opened FUSE fd, or the
+mount.fuse3 "setuid=USER" option).
+
+
+Security model
+--------------
+
+  - The FUSE server runs under the confinement defined by its .service unit,
+    not under the mount caller's identity, privileges, or namespaces.
+
+  - The server has no access to the caller's filesystem. Anything it needs
+    (the backing device or file, /dev/fuse) is opened by the privileged
+    fuservicemount3 helper and passed to the server over the socket. The
+    server can refuse to accept further passed file descriptors once it has
+    what it needs.
+
+  - fuservicemount3 opens a path for the server only if the mount command
+    line names it: as an argument, as the value in a name=value option, or
+    glued to a short option as in "-J/dev/sdb1". The administrator can allow
+    more paths per filesystem subtype in /etc/fuse.conf:
+
+        service_open_path = ext4 /dev/sd*
+
+    It refuses any other path with EPERM.
+
+  - The only setuid-root component is fuservicemount3, which performs just the
+    mount and the file-descriptor hand-off.
+
+This is the same trust boundary as fusermount3, but with the filesystem
+implementation itself kept out of the privileged and caller-facing paths.
+
+
+Who establishes the connection
+------------------------------
+
+Three parties touch the service socket, but only one dials it:
+
+  - systemd owns and listens on the socket. Starting the .socket unit creates
+    the listening socket at <service-socket-dir>/<subtype>; no server is
+    running yet.
+
+  - fuservicemount3 (the helper) is the socket client. When you mount, it
+    connects to that socket -- after dropping back to your real, unprivileged
+    user id, so the kernel checks the socket's permissions against you, not
+    against root. This is the access-control gate: only users the socket
+    grants connect (write) permission to can mount.
+
+  - systemd accepts the connection and, because the .socket unit uses
+    Accept=yes, starts a fresh per-connection server instance and hands it the
+    already-connected socket. The server never connects or accepts; it
+    inherits the live connection.
+
+So to control who may mount a given filesystem, set SocketUser=, SocketGroup=
+and SocketMode= for its .socket unit, for example with
+"systemctl edit myfs.socket". A chmod or chown on the socket file itself is
+lost when the socket unit restarts, because systemd creates the file anew.
+
+
+Troubleshooting
+---------------
+
+  - "mounts the old way / service is ignored": confirm the socket exists with
+    "fuservicemount3 -t fuse.<subtype> --check", that <service-socket-dir>
+    matches how libfuse was built, and that the .socket unit is started.
+
+  - "fuservicemount3: not found" or permission errors: verify the helper is
+    installed in sbindir and is setuid root.
+
+  - "<path>: file must be in command line arguments or in /etc/fuse.conf":
+    the server asked for a path the mount command line does not name. Add a
+    service_open_path line for it (see "Security model").
+
+  - server-side errors: because the server logs to its own journal, inspect it
+    with "journalctl -u myfs@*" (the example units log to the kernel ring
+    buffer via /dev/ttyprintk, viewable with dmesg).
+
+
+See also
+--------
+
+  README.service-mount-dev   writing a FUSE server that runs as a service
+  fuservicemount3(8)
+  mount.fuse3(8)
+  fusermount3(1)
+  mount(8)
+  systemd.socket(5)
diff --git a/doc/README.service-mount-dev b/doc/README.service-mount-dev
new file mode 100644
index 000000000000..c39bcb5e4d51
--- /dev/null
+++ b/doc/README.service-mount-dev
@@ -0,0 +1,456 @@
+Writing a FUSE server that runs as a socket service
+===================================================
+
+This document is for developers who want their FUSE server to be mountable as
+a sandboxed systemd socket service, using the fuse_service_* API declared in
+fuse_service.h. Administrators and users who only want to mount such a
+filesystem should read README.service-mount instead.
+
+The complete working examples referenced throughout are:
+
+    example/service_ll.c     low-level API server
+    example/service_hl.c     high-level API server
+    example/single_file.c    backing-store helper shared by both
+    example/service_ll@.service, example/service_ll.socket.in   systemd units
+
+
+The execution model
+--------------------
+
+A service-mount server does not mount anything itself and does not run in the
+mounting user's context. Instead:
+
+  1. systemd listens on a per-subtype UNIX socket (Accept=yes) and starts one
+     confined instance of your server per incoming mount request.
+
+  2. The privileged fuservicemount3 helper connects to that socket, opens
+     /dev/fuse, and passes the device fd plus your command-line arguments to
+     the server.
+
+  3. Your server cannot open files itself (its sandbox has no access to the
+     caller's filesystem or to /dev), so it asks the helper to open any
+     backing files or block devices on its behalf and pass the descriptors
+     back.
+
+  4. Your server binds the FUSE session to the passed /dev/fuse fd and asks
+     the helper to perform the mount. Requests start flowing immediately.
+
+Everything the server needs from the outside world therefore arrives over the
+socket; the server never needs mount permission and never touches the
+caller's environment.
+
+
+The mount protocol
+------------------
+
+S and H denote the two parties:
+
+  S = the FUSE server   -- your binary, one <subtype>@.service instance
+  H = fuservicemount3   -- the setuid-root mount helper; the socket client
+
+Transport:
+
+  - one AF_UNIX SOCK_SEQPACKET socket, created by systemd at
+    <service-socket-dir>/<subtype> (e.g. /run/fuse/myfs)
+  - H connect()s as the real user (that uid gates who may mount); systemd
+    accept()s (Accept=yes) and hands the connected fd to a fresh S, which
+    adopts it in fuse_service_accept()
+  - one message per datagram (sendmsg with MSG_EOR); a passed fd travels as
+    SCM_RIGHTS ancillary data, exactly one fd per message
+  - every multi-byte field is in network byte order; no message exceeds
+    FUSE_SERVICE_MAX_CMD_SIZE (65536 bytes)
+  - after "DOIT" FUSE traffic uses /dev/fuse, not this socket; H keeps
+    serving commands until S sends "BYEE" or closes the socket
+
+Every message begins with a 4-byte magic that spells the quoted tag in ASCII
+(e.g. "OPEN" is 0x4f50454e), so a message is legible in a hex dump. Most tags
+are operation mnemonics (OPEN, BDEV, TYPE, NAME, MNTP, DOIT, BYEE, ...); the
+handshake pair is not: "SAFT" (the HELLO command) and "LAST" (its reply) are
+named after the film "Safety Last!". Structures, verbatim from
+fuse_service_priv.h:
+
+    struct fuse_service_packet { uint32_t magic; };
+
+    struct fuse_service_hello {              /* "SAFT" */
+        struct fuse_service_packet p;
+        uint16_t min_version, max_version;   /* both 1 */
+        uint32_t flags;  /* ALLOW_OTHER 1<<0 | FUSEBLK 1<<1; what H allows */
+    };
+    struct fuse_service_hello_reply {        /* "LAST" */
+        struct fuse_service_packet p;
+        uint16_t version, padding;           /* version 1 */
+    };
+    struct fuse_service_simple_reply {       /* "REPL" */
+        struct fuse_service_packet p;
+        uint32_t error;  /* 0, else positive errno */
+    };
+    struct fuse_service_requested_file {     /* "FILE", carries one fd */
+        struct fuse_service_packet p;
+        uint32_t error;  /* 0, else positive errno and no fd */
+        char path[];     /* echoes the request path; NUL-terminated */
+    };
+    struct fuse_service_open_command {       /* "OPEN" file / "BDEV" device */
+        struct fuse_service_packet p;
+        uint32_t open_flags;    /* O_* */
+        uint32_t create_mode;
+        uint32_t request_flags; /* QUIET 1<<0 */
+        uint32_t block_size;    /* "BDEV" only */
+        char path[];
+    };
+    struct fuse_service_fsopen_command {     /* "TYPE" */
+        struct fuse_service_packet p;
+        uint32_t fsopen_flags;  /* FUSEBLK 1<<0, set iff fstype is fuseblk */
+    };
+    struct fuse_service_string_command {     /* "NAME" / "OPTS" / "MTAB" */
+        struct fuse_service_packet p;
+        char value[];
+    };
+    struct fuse_service_mountpoint_command { /* "MNTP" */
+        struct fuse_service_packet p;
+        uint16_t expected_fmt, padding;  /* S_IFDIR / S_IFREG, or 0 */
+        char value[];  /* the mountpoint */
+    };
+    struct fuse_service_mount_command {      /* "DOIT" */
+        struct fuse_service_packet p;
+        uint32_t ms_flags;  /* MS_* */
+    };
+    struct fuse_service_bye_command {        /* "BYEE" */
+        struct fuse_service_packet p;
+        uint32_t exitcode;
+    };
+
+The "argv" descriptor is a memfd; its bytes are one header, then argc entries,
+then the packed argument strings:
+
+    struct fuse_service_memfd_argv { uint32_t magic /* "ARGS" */, argc; };
+    struct fuse_service_memfd_arg  { uint32_t pos, len; };  /* x argc */
+
+The whole memfd is at most FUSE_SERVICE_MAX_ARGV_SIZE (1 MiB) and argc is at
+least 1; the server refuses a file that breaks either rule.
+
+Message sequence.  "A -> B msg" = A sends msg to B.  A bracketed [call] names
+the fuse_service_* function that drives the step; "local:" steps send nothing.
+
+  handshake  [fuse_service_accept]
+    H -> S  "SAFT"  fuse_service_hello
+    S -> H  "LAST"  fuse_service_hello_reply
+
+  fd handover, both pushed by H unsolicited  [fuse_service_accept]
+    H -> S  "FILE"  fuse_service_requested_file +fd   path "argv"
+    H -> S  "FILE"  fuse_service_requested_file +fd   path "fusedev"
+    local:  S reads argv out of the memfd  [fuse_service_append_args]
+
+  backing store, repeated per file, may be none
+    S -> H  "OPEN" / "BDEV"  fuse_service_open_command
+            [fuse_service_request_file / fuse_service_request_blockdev]
+    H -> S  "FILE"  fuse_service_requested_file +fd   (or error and no fd)
+            [fuse_service_receive_file]
+    local:  setsockopt(SO_PASSRIGHTS, 0)  [fuse_service_finish_file_requests]
+
+  mount  [fuse_service_session_mount].  S sends each command below; H answers
+         every one with  H -> S  "REPL"  fuse_service_simple_reply, whose
+         nonzero errno aborts the mount.
+    local:  bind se to /dev/fd/<fusedev>  (fuse_session_mount)
+    S -> H  "TYPE"  fuse_service_fsopen_command
+    S -> H  "NAME"  fuse_service_string_command        (mtab source)
+    S -> H  "MNTP"  fuse_service_mountpoint_command
+    S -> H  "OPTS"  fuse_service_string_command        (optional)
+    S -> H  "MTAB"  fuse_service_string_command        (optional)
+    S -> H  "DOIT"  fuse_service_mount_command         (H mounts here)
+
+  shutdown  [fuse_service_send_goodbye]
+    S -> H  "BYEE"  fuse_service_bye_command   no reply; S closes socket
+
+README.service-mount-flow follows this sequence through the code of both
+sides, with the checks each side makes.
+
+
+The two entry points
+--------------------
+
+There are two ways to write the server, mirroring the normal libfuse APIs:
+
+  - High-level API: do the service setup, then call fuse_service_main(), the
+    service-aware counterpart of fuse_main(). See example/service_hl.c.
+
+  - Low-level API: do the service setup, create the session yourself, call
+    fuse_service_session_mount(), and run your own event loop. See
+    example/service_ll.c.
+
+Both share the same startup, resource-request, and shutdown sequence.
+
+IMPORTANT: define FUSE_USE_VERSION to at least FUSE_MAKE_VERSION(3, 19) and
+include <fuse_service.h>. Do NOT call fuse_daemonize(): a service must stay in
+the foreground so systemd can track it (fuse_service_session_mount and
+fuse_service_main arrange this for you). Service mounts do not support
+synchronous FUSE_INIT yet: FUSE_INIT reaches the server only after
+fuservicemount3 has performed the mount. Do not call
+fuse_daemonize_early_start() either.
+
+
+API reference
+-------------
+
+The full per-call documentation lives in fuse_service.h (and fuse.h for the
+high-level fuse_service_main). Unless noted, each int-returning call returns 0
+on success or a negative errno. In call order:
+
+    /* startup */
+    int  fuse_service_accept(struct fuse_service **sfp);
+    bool fuse_service_accepted(const struct fuse_service *sf);
+    int  fuse_service_append_args(struct fuse_service *sf,
+             struct fuse_args *args);
+    int  fuse_service_parse_cmdline_opts(struct fuse_args *args,
+             struct fuse_cmdline_opts *opts);        /* returns 0 / -1 */
+
+    /* capability negotiation */
+    bool fuse_service_can_allow_other(const struct fuse_service *sf);
+    bool fuse_service_can_fuseblk(const struct fuse_service *sf);
+
+    /* backing files: request, receive each fd, then stop fd passing */
+    int  fuse_service_request_file(const struct fuse_service *sf,
+             const char *path, int open_flags, mode_t create_mode,
+             unsigned int request_flags);
+    int  fuse_service_request_blockdev(const struct fuse_service *sf,
+             const char *path, int open_flags, mode_t create_mode,
+             unsigned int request_flags, unsigned int block_size);
+    int  fuse_service_receive_file(const struct fuse_service *sf,
+             const char *path, int *fdp);
+    int  fuse_service_finish_file_requests(const struct fuse_service *sf);
+
+    /* mount */
+    void fuse_service_expect_mount_format(struct fuse_service *sf,
+             mode_t expected_fmt);
+    int  fuse_service_session_mount(struct fuse_service *sf,
+             struct fuse_session *se, mode_t expected_fmt,
+             struct fuse_cmdline_opts *opts);
+    int  fuse_service_main(struct fuse_service *sf, struct fuse_args *args,
+             const struct fuse_operations *op, void *user_data);
+
+    /* shutdown */
+    int  fuse_service_send_goodbye(struct fuse_service *sf, int exitcode);
+    void fuse_service_release(struct fuse_service *sf);
+    void fuse_service_destroy(struct fuse_service **sfp);
+    int  fuse_service_exit(int ret);
+
+    #define FUSE_SERVICE_REQUEST_FILE_QUIET (1U << 0)
+
+fuse_service_receive_file sets *fdp to a valid fd (>= 0) or a negated errno
+from the helper's open attempt; the call itself returns nonzero only on a
+socket-level failure. fuse_service_accept always initialises *sfp; test
+fuse_service_accepted (true iff *sfp != NULL) to learn whether the program was
+actually launched as a service.
+
+
+Startup sequence
+----------------
+
+The first thing main() does is accept the service context:
+
+    struct fuse_service *service;
+
+    if (fuse_service_accept(&service))
+        goto error;                 /* socket/handshake failure */
+
+    if (!fuse_service_accepted(service))
+        goto error;                 /* not started as a service */
+
+fuse_service_accept() looks for the socket handed to the process by systemd,
+performs the protocol handshake, and receives the argument vector and the
+/dev/fuse fd. It always initialises *service; use fuse_service_accepted() to
+find out whether the program is actually running as a service (it returns
+false, with *service == NULL, when there is no service socket).
+
+The example servers require a service and exit otherwise (their error paths
+run only once the context is valid). A server that also wants to support
+traditional invocation can branch on fuse_service_accepted() and fall back to
+fuse_main() / fuse_session_mount(); in that case do not call the other
+fuse_service_* functions, which assume a valid service context.
+
+Next, fold the service-supplied arguments into the fuse_args built from the
+argc and argv of main(), and parse them:
+
+    struct fuse_args args = FUSE_ARGS_INIT(argc, argv);
+
+    if (fuse_service_append_args(service, &args))   /* add helper's args */
+        goto error;
+
+    if (fuse_opt_parse(&args, &priv, my_opts, my_opt_proc))   /* your opts */
+        goto error;
+
+For the low-level API also extract the common command-line options:
+
+    struct fuse_cmdline_opts opts = { };
+
+    if (fuse_service_parse_cmdline_opts(&args, &opts))
+        goto error;
+
+fuse_service_parse_cmdline_opts() is the service-mount analogue of
+fuse_parse_cmdline(). It does NOT validate the mountpoint; that is the
+helper's job. As usual, a missing -o subtype=/fsname= defaults the subtype to
+the program's basename.
+
+
+Requesting backing files and block devices
+-------------------------------------------
+
+Because the sandbox cannot open files, the server asks the helper to open them
+and send back the descriptor. This is a two-step request/receive pattern (see
+single_file_service_open() in example/single_file.c):
+
+    /* ask the helper to open it */
+    fuse_service_request_file(service, path, open_flags, create_mode, flags);
+    /* or, for a block device: */
+    fuse_service_request_blockdev(service, path, open_flags, create_mode,
+                                  flags, block_size);
+
+    /* then collect the descriptor */
+    int fd;
+    fuse_service_receive_file(service, path, &fd);
+
+A block_size of 0 leaves the block size of the device unchanged.
+
+On success fd is a valid descriptor. A negative fd is a (negated) errno from
+the helper's open attempt — single_file.c uses this to downgrade an O_RDWR
+request to O_RDONLY when the backing store is read-only. Pass
+FUSE_SERVICE_REQUEST_FILE_QUIET in the request flags to suppress the helper's
+error message when a failure is expected.
+
+The helper opens only a path that the mount command line names or that a
+service_open_path line in /etc/fuse.conf lists, and compares the strings
+exactly; any other path gets fd == -EPERM. Request the path as the user wrote
+it, not a canonicalized or rebuilt form. A relative path resolves against the
+directory mount was run in.
+
+Once you have every descriptor you need, close the door on further fd passing:
+
+    fuse_service_finish_file_requests(service);
+
+This tells the kernel to reject any additional descriptors on the socket
+(via SO_PASSRIGHTS where available), so a compromised or malicious helper
+cannot smuggle in more fds afterwards.
+
+
+Capability negotiation
+----------------------
+
+During the handshake the helper advertises what it is willing to do. Query it
+before relying on those behaviours:
+
+    fuse_service_can_allow_other(service)   /* may honour -o allow_other */
+    fuse_service_can_fuseblk(service)       /* may mount a fuseblk filesystem */
+
+
+Mounting
+--------
+
+fuservicemount3 mounts on a directory or on a regular file, and the kernel
+gives the filesystem root the type of the mountpoint. Every access to the
+root fails with EIO when the root your server reports has a different type.
+To make fuservicemount3 refuse such a mountpoint before it mounts, pass the
+type of your root (S_IFDIR or S_IFREG):
+
+    fuse_service_expect_mount_format(service, S_IFDIR);
+
+This call is optional. Without it, fuservicemount3 does not check the root
+type. A low-level server can instead pass the type as the third argument of
+fuse_service_session_mount().
+
+High-level API — hand off to fuse_service_main(), which builds the operations,
+performs the mount, and runs the loop:
+
+    ret = fuse_service_main(service, &args, &my_oper, NULL);
+
+Low-level API — create the session, install signal handlers, then mount:
+
+    se = fuse_session_new(&args, &my_ll_oper, sizeof(my_ll_oper), NULL);
+    ...
+    fuse_set_signal_handlers(se);
+
+    if (fuse_service_session_mount(service, se, S_IFDIR, &opts))
+        goto error;
+
+    fuse_session_loop(se);          /* or fuse_session_loop_mt(se, config) */
+
+fuse_service_session_mount() binds the session to the passed /dev/fuse fd and
+asks the helper to mount the filesystem. It forces foreground operation and
+chdir("/") so you do not need (and must not) call fuse_daemonize(). After it
+returns successfully the kernel is already routing requests to your server, so
+enter your event loop promptly.
+
+
+Shutdown
+--------
+
+Tell the helper you are leaving, releasing and destroying the service context:
+
+    fuse_service_send_goodbye(service, exitcode);   /* report exit status */
+    fuse_service_release(service);                  /* free socket-side state */
+    ...
+    fuse_service_destroy(&service);                 /* free the context */
+
+    return fuse_service_exit(ret);                  /* map ret to an exit code */
+
+In the examples, send_goodbye is sent once mounting has succeeded and the loop
+is about to start, and again on the error paths; fuse_service_exit() at the end
+of main() converts the server's return value into the exit status systemd
+expects. fuse_service_destroy() takes a pointer to the pointer and clears it.
+
+
+The systemd units
+-----------------
+
+Ship two units per filesystem, named after the subtype (the part after
+"fuse." in the mount type). For subtype "myfs":
+
+  myfs.socket    — the listening socket. It must use SOCK_SEQPACKET, accept
+                   each connection, and listen at the configured service
+                   socket directory under the subtype name. The example
+                   socket file is processed by meson, which substitutes the
+                   build-time values:
+
+                       [Socket]
+                       ListenSequentialPacket=@FUSE_SERVICE_SOCKET_DIR_RAW@/myfs
+                       Accept=yes
+                       SocketMode=@FUSE_SERVICE_SOCKET_PERMS@
+                       RemoveOnStop=yes
+
+                       [Install]
+                       WantedBy=sockets.target
+
+  myfs@.service  — the server template, one instance per connection. Set
+                   ExecStart to your binary and lock the unit down as tightly
+                   as the filesystem allows. example/service_ll@.service is a
+                   good starting point: DynamicUser, no capabilities, private
+                   mount/network/pid namespaces, a @system-service syscall
+                   filter, and OOMPolicy=continue so the filesystem is not
+                   torn down under memory pressure.
+
+The socket name must match the subtype your server reports (via the program
+basename or -o subtype=), because that is the name fuservicemount3 looks for
+under the service socket directory.
+
+
+Building and installing
+-----------------------
+
+Build a server the usual way, linking against fuse3 and including the new
+header:
+
+    gcc -Wall single_file.c service_ll.c \
+        `pkg-config fuse3 --cflags --libs` -o service_ll
+
+Install the binary, point ExecStart at it, install the .service and .socket
+units into the systemd unit directory, then "systemctl daemon-reload" and
+"systemctl start myfs.socket". From there the filesystem is mounted exactly as
+described in README.service-mount.
+
+
+See also
+--------
+
+  fuse_service.h             the full fuse_service_* API reference (Doxygen)
+  README.service-mount       installing and mounting a service filesystem
+  README.service-mount-flow  the mount sequence through the code
+  example/service_ll.c, example/service_hl.c, example/single_file.c
+  systemd.service(5), systemd.socket(5), systemd.exec(5)
diff --git a/doc/README.service-mount-flow b/doc/README.service-mount-flow
new file mode 100644
index 000000000000..bd5c4dee8b10
--- /dev/null
+++ b/doc/README.service-mount-flow
@@ -0,0 +1,201 @@
+How a service mount is set up
+=============================
+
+How a fuse server, the libfuse service code, and the fuservicemount3 mount
+helper set up a mount together: who talks to whom, over which transport, and
+where each side checks what the other sent. README.service-mount-dev
+describes the protocol and the API; this file follows the code.
+
+
+Participants
+------------
+
+  - fuservicemount3          util/mount_service.c   separate process, setuid
+                                                    root, spawned by
+                                                    mount.fuse3 or run by hand
+  - libfuse service code     lib/fuse_service.c     linked into the fuse server
+  - fuse server              example/service_ll.c   same process as the library
+
+The flow graph below puts the process boundary between its first two
+columns. lib/fuse_service.c is compiled into the fuse server, so placing
+fuservicemount3 between the other two would draw two boundaries where there
+is one.
+
+Transports:
+
+  - AF_UNIX SOCK_SEQPACKET between fuservicemount3 and lib/fuse_service.c.
+    fuservicemount3 calls connect(); the fuse server receives the already
+    connected socket as SD_LISTEN_FDS_START via systemd socket activation
+    (Accept=yes), so fuse_service_accept() never calls accept(2).
+  - SCM_RIGHTS on that socket for the argv memfd, /dev/fuse, and each file
+    the server asks for with "OPEN" or "BDEV".
+
+
+Overview
+--------
+
+fuservicemount3 runs as root and does everything that needs privilege. The
+fuse server runs sandboxed and only asks. "Entry points" and "Flow" below show
+the steps and the main checks.
+
+legend: ---> request, data or file descriptor;  <--- reply or request back
+
+ user: mount -t fuse.<subtype> <image> <mountpoint>
+   |
+   v
+ mount.fuse3 -> fuservicemount3                     fuse server
+ (setuid root, trusted)                             (systemd service, sandboxed)
+ -----------------------------------------------    -----------------------------
+ connect /run/fuse/<subtype>         ----------->   systemd starts the server
+ hello, argv memfd, /dev/fuse        ----------->   fuse_service_accept()
+                                                    parse the arguments
+ path named on the command line      <-----------   OPEN <image>
+ or listed in fuse.conf?
+   yes: open as the user, send fd    ----------->   keep the fd as backing store
+   no:  EPERM                                       fuse_service_finish_file_requests()
+ mount point on the command line?    <-----------   MNTP <mountpoint>
+   open it as the user and pin it
+ mount the fuse filesystem           <-----------   DOIT
+ exit                                <-----------   BYEE
+   |                                                serve FUSE requests from the
+   v                                                kernel until umount
+ mount(8) returns
+
+
+Entry points
+------------
+
+Two binaries link the same mount_service.c (util/meson.build) and both funnel
+into mount_service_main(). mount(8) only ever execs mount.fuse3;
+fuservicemount3 is reached by direct invocation or because mount.fuse3
+spawned it, which is also the only place a second process appears. The last
+step below, mount_service_connect(), is where the socket to the fuse server
+is created and connected.
+
+ mount(8)  -t fuse.<subtype>  <source> <mountpoint> [-o opts]
+   |  execs /sbin/mount.fuse3            user, directly:
+   |                                     fuservicemount3 <source> <mountpoint> -t fuse.<subtype>
+   v                                       v
+ /sbin/mount.fuse3                       /sbin/fuservicemount3
+ util/mount.fuse.c   main()              util/fuservicemount.c  main()
+   |  strips "fuse." / "fuseblk."          |  also spawned by mount.fuse3
+   |  no setuid=, no drop_privileges       |  when not root, see below
+   |    -> try_service_main()              |
+   v                                       |  exactly "-t FSTYPE --check"?
+ try_service_main()                        |    exit 0/1, mounts nothing
+   no socket, no write access, or          |
+   name too long -> FALLBACK_NEEDED        |
+   +- getuid() != 0                        |
+   |    spawn fuservicemount3           ---+  a SECOND process starts here;
+   |      fails -> FALLBACK_NEEDED         |  the parent waitpid()s
+   |                                       |  and returns its exit status
+   +- getuid() == 0                        |
+        mount_service_main()               +-> mount_service_main()
+             |                                 |
+             +----------------+----------------+
+                              v
+             mount_service_main()          util/mount_service.c
+               read fuse.conf as the user
+               mount_service_init()
+                 subtype from the fstype, reject a '/' in it
+                 open the working directory as the user
+               mount_service_connect()
+                 connect to /run/fuse/<subtype> as the user
+                 path longer than sun_path -> exit failure
+                 send buffer too small, no socket, or no
+                 listener -> MOUNT_SERVICE_FALLBACK_NEEDED
+                             |
+                             v
+      a systemd .socket unit with Accept=yes is listening on
+      /run/fuse/<subtype>; it accepts the connection and spawns the
+      fuse server, handing it the connected fd as SD_LISTEN_FDS_START.
+      example/ carries units for the examples (null, service_ll, service_hl:
+      *.socket.in configured into *.socket, plus *@.service), none of which
+      meson installs. The socket directory comes from the meson option
+      service-socket-dir, built into FUSE_SERVICE_SOCKET_DIR (fuse_config.h).
+                             |
+                             v
+              continues in the three-column graph below
+
+MOUNT_SERVICE_FALLBACK_NEEDED on the mount.fuse3 path makes main() in
+mount.fuse3 run the filesystem server program itself, as it did before
+service mounts: /bin/sh -c "<subtype> [<source>] <mountpoint> [-o <options>]".
+
+
+Flow
+----
+
+The horizontal rule across the middle is the phase boundary. Above it the
+server is blocked inside its single fuse_service_accept() call and
+fuservicemount3 does the pushing (hello, argv memfd, /dev/fuse). Below it
+that call has returned, the server drives every step, and each socket message
+travels the other way: the server sends a command, fuservicemount3 replies.
+
+The server sends its "OPEN" and "BDEV" requests before
+fuse_service_finish_file_requests(), and the mount commands from
+fuse_service_session_mount() after it.
+
+ fuservicemount3 (separate process)       #  lib/fuse_service.c                        |  fuse server
+ util/mount_service.c                     #  (linked into the server)                  |  example/service_ll.c
+ setuid root, or mount.fuse3 as root      #                                            |
+==========================================+============================================+========================
+                                          #              one process                   |
+ mount_service_connect() done             #   systemd started the fuse server          |
+   (see "Entry points" above)             #   with the connected fd                    |
+                                          #                                            |
+                                          #                                            |  main()
+                                          #  fuse_service_accept()  <------------------+--  fuse_service_accept()
+                                          #    check the socket fd from systemd        |
+                                          #                                            |
+ mount_service_send_hello() --------------+-> negotiate_hello()                        |
+   "SAFT": versions and flags             #     bad magic, version or flags -> error   |
+   "LAST" hello reply  <------------------+-- reply with the chosen version            |
+                                          #                                            |
+ mount_service_capture_args()             #                                            |
+   copy argv into a memfd                 #                                            |
+   memfd larger than                      #                                            |
+   FUSE_SERVICE_MAX_ARGV_SIZE             #                                            |
+     -> exit failure                      #                                            |
+ mount_service_send_required_files()      #                                            |
+   "FILE" + argv memfd -------------------+-> fuse_service_receive_file(ARGV)          |
+   "FILE" + /dev/fuse --------------------+-> fuse_service_receive_file(FUSEDEV)       |
+-- fuse_service_accept() returns ---------+-- traffic direction reverses --------------+-- server drives below --
+ main loop: while (running)               #                                            |
+   mount_service_receive_command()        #  fuse_service_append_args()  <-------------+--  fuse_service_append_args()
+     command larger than                  #    read the arguments from the memfd       |
+     FUSE_SERVICE_MAX_CMD_SIZE            #    memfd larger than                       |
+       -> exit failure                    #      FUSE_SERVICE_MAX_ARGV_SIZE,           |
+                                          #    argc 0 or more than the memfd holds,    |
+                                          #    argument longer than the memfd          |
+                                          #      -> -EBADMSG                           |  fuse_opt_parse()
+                                          #  fuse_service_parse_cmdline_opts()  <------+--  fuse_service_parse_cmdline_opts()
+                                          #                                            |
+   "OPEN" / "BDEV"  <---------------------+-- fuse_service_request_file()  <-----------+--  single_file_service_open()
+     not on the command line and not      #   or fuse_service_request_blockdev()       |
+     listed in fuse.conf -> EPERM         #                                            |
+     open it as the user                  #                                            |
+     "FILE" + fd, or -errno --------------+-> fuse_service_receive_file(path)          |
+                                          #                                            |
+                                          #  fuse_service_finish_file_requests()  <----+--  fuse_service_finish_file_requests()
+                                          #    no more fds accepted                    |  fuse_session_new()
+                                          #                                            |
+                                          #  fuse_service_session_mount()  <-----------+--  fuse_service_session_mount()
+   "TYPE"  <------------------------------+-- one command per mount parameter          |
+     fuseblk, not root -> EPERM           #                                            |
+   "NAME"  <------------------------------+--                                          |
+   "MNTP"  <------------------------------+--                                          |
+     not on the command line -> EINVAL    #                                            |
+     open it as the user and pin it       #                                            |
+   "OPTS"  <------------------------------+--                                          |
+     allow_other/allow_root, not root,    #                                            |
+     no user_allow_other -> EPERM         #                                            |
+   "MTAB"  <------------------------------+--                                          |
+   "DOIT"  <------------------------------+--                                          |
+     not root: limit mounts, reject       #                                            |
+     unsafe flags, check mount point      #                                            |
+     mount the fuse filesystem            #                                            |
+   "REPL" after each command -------------+-> error -> -errno to the caller            |
+                                          #                                            |
+   "BYEE"  <------------------------------+-- fuse_service_send_goodbye()  <-----------+--  fuse_service_send_goodbye(0)
+ exit                                     #                                            |  fuse_session_loop[_mt]()
+                                          #                                            |    serves until umount
diff --git a/doc/fuservicemount3.8 b/doc/fuservicemount3.8
index 18e285c1ab29..fa2358f3cfed 100644
--- a/doc/fuservicemount3.8
+++ b/doc/fuservicemount3.8
@@ -16,9 +16,17 @@ fuservicemount3 \- mount a FUSE filesystem that runs as a system socket service
 
 .SH DESCRIPTION
 Mount a filesystem using a FUSE server that runs as a socket service.
-These servers can be contained using the platform's service management
-framework.
-
+Unlike a traditional FUSE filesystem, which runs in the mount caller's
+context, such a server runs as an independent, sandboxed systemd service.
+\fBfuservicemount3\fP connects to the per-type service socket, hands the
+running server the \fI/dev/fuse\fP device and any backing files it needs,
+and performs the mount on its behalf. These servers can therefore be
+contained using the platform's service management framework.
+.PP
+\fBfuservicemount3\fP is installed setuid root so that unprivileged users
+can mount filesystems handled by a service. It is normally invoked
+indirectly by \fBmount.fuse3\fP(8), not run directly.
+.PP
 The FUSE server may ask fuservicemount3 to open files on its behalf.
 fuservicemount3 opens a path only in these cases:
 .IP \- 2
@@ -34,15 +42,145 @@ A service_open_path line in /etc/fuse.conf lists the path for the filesystem
 type.
 .PP
 It refuses any other request with EPERM.
-
-The second form checks if there is a FUSE service available for the given
-filesystem type.
+.PP
+The second form checks whether a FUSE service is available for the given
+filesystem type, without mounting anything.
+.SH FILESYSTEM REQUIREMENTS
+This is not a transparent wrapper for arbitrary FUSE programs. Only a
+filesystem whose server is written to the libfuse service API can be mounted
+this way. A conventional server calls \fBfuse_main\fP(3), which opens
+\fI/dev/fuse\fP and performs the mount itself. The service sandbox does not
+permit this, so such a server cannot be used unmodified.
+.PP
+A service-capable server instead:
+.IP \- 2
+accepts the listening socket that systemd hands it, and receives its
+arguments and the \fI/dev/fuse\fP descriptor over that socket, rather than
+opening the device itself;
+.IP \- 2
+asks the helper to open any backing files or block devices on its behalf,
+because its sandbox has no direct filesystem access; and
+.IP \- 2
+lets the helper perform the mount, staying in the foreground under systemd.
+.PP
+The server binary, its \fB@.service\fP unit, and its \fB.socket\fP unit must
+all be installed before the type can be mounted. See \fBEXAMPLES\fP below, the
+\fIservice_ll.c\fP and \fIservice_hl.c\fP example servers, the
+\fI<fuse_service.h>\fP header, and the \fIREADME.service-mount-dev\fP document
+for how to build one.
+.SH OPTIONS
+.TP
+.B source
+The filesystem source, passed on to the running server (for example a
+backing device or file). May be empty.
+.TP
+.B mountpoint
+Where to mount the filesystem.
+.TP
+.BI -t " fstype"
+The filesystem type, of the form \fBfuse.\fIsubtype\fR or
+\fBfuseblk.\fIsubtype\fR. The \fIsubtype\fR selects the service socket.
+.TP
+.BI -o " options"
+Mount options to forward to the server.
+.TP
+.B --check
+Only test whether a service socket exists for the type given with \fB-t\fP
+and whether the calling user may connect to it; do not mount. Exit status is
+zero if both hold, non-zero otherwise.
+.SH FILES
+.TP
+.I /run/fuse/<subtype>
+The default location of the per-filesystem service socket. The directory is
+configurable at build time (meson option \fBservice-socket-dir\fP).
+.SH EXAMPLES
+A complete walk-through using the \fIservice_ll\fP example filesystem that
+ships with libfuse.
+.SS "What it is for"
+\fIservice_ll\fP exports a single file or block device as a one-file
+filesystem. Running it as a service keeps the server inside a systemd sandbox
+\(em its own unprivileged user, private namespaces, and no capabilities \(em
+while still letting a permitted user mount it with an ordinary \fBmount\fP
+command. The privileged work (opening the backing device and performing the
+mount) is done only by the setuid \fBfuservicemount3\fP helper. The
+same recipe applies to any server written with the libfuse service API.
+.SS "Setting up the service (administrator, once)"
+The source for this example ships with the libfuse distribution in its
+\fIexample\fP directory: \fIservice_ll.c\fP together with its helper
+\fIsingle_file.c\fP make up the server, and \fIservice_ll@.service\fP and
+\fIservice_ll.socket\fP are its systemd units. From that directory, build the
+server and install the binary on the root filesystem:
+.PP
+.RS
+.nf
+gcc -Wall single_file.c service_ll.c $(pkg-config fuse3 --cflags --libs) -o service_ll
+sudo install -m 0755 service_ll /usr/local/sbin/service_ll
+.fi
+.RE
+.PP
+libfuse provides two systemd units for this example: \fIservice_ll@.service\fP
+(the sandboxed server) and \fIservice_ll.socket\fP (the activation socket,
+already configured to listen at \fI/run/fuse/service_ll\fP). Edit the
+service unit's \fBExecStart\fP to point at the installed binary:
+.PP
+.RS
+.nf
+ExecStart=/usr/local/sbin/service_ll
+.fi
+.RE
+.PP
+Install both units, reload systemd, and start the socket:
+.PP
+.RS
+.nf
+sudo cp service_ll@.service service_ll.socket /run/systemd/system/
+sudo systemctl daemon-reload
+sudo systemctl start service_ll.socket
+.fi
+.RE
+.PP
+Only the socket is running now; systemd starts a fresh, isolated server
+instance on demand for each mount.
+.SS "Mounting and using it"
+Confirm a service is available for the type (this prints nothing; the exit
+status is the answer):
+.PP
+.RS
+.nf
+fuservicemount3 -t fuse.service_ll --check && echo available
+.fi
+.RE
+.PP
+Mount it, passing the backing device or file as the source. Run this as root
+or from an \fI/etc/fstab\fP entry that permits the mount:
+.PP
+.RS
+.nf
+mount -t fuse.service_ll /dev/sda /mnt
+.fi
+.RE
+.PP
+\fBmount.fuse3\fP(8) notices the service, \fBfuservicemount3\fP opens
+\fI/dev/sda\fP and performs the mount, and the data appears under \fI/mnt\fP.
+Unmount it like any other FUSE filesystem:
+.PP
+.RS
+.nf
+fusermount3 -u /mnt
+.fi
+.RE
+.PP
+For the full hardened unit files and further detail, see the
+\fIservice_ll@.service\fP and \fIservice_ll.socket\fP files shipped with
+libfuse and the \fIREADME.service-mount\fP document.
 .SH "AUTHORS"
 .LP
 The author of the fuse socket service code is Darrick J. Wong <djwong@kernel.org>.
 Debian GNU/Linux distribution.
 .SH SEE ALSO
+.BR mount.fuse3 (8)
 .BR fusermount3 (1)
 .BR fusermount (1)
 .BR mount (8)
 .BR fuse (4)
+.BR systemd.socket (5)
diff --git a/doc/mainpage.dox b/doc/mainpage.dox
index 36ba3bcba268..9de96e1410ab 100644
--- a/doc/mainpage.dox
+++ b/doc/mainpage.dox
@@ -28,6 +28,19 @@ separate set of API functions.
 The high-level API that is primarily specified in fuse.h. The
 low-level API that is primarily documented in fuse_lowlevel.h.
 
+## Running a filesystem as a systemd service ##
+
+A FUSE server can also be run as a sandboxed, socket-activated systemd
+service rather than as a child of the mounting process. In this model the
+server runs under its own unprivileged identity and in private namespaces,
+while a small setuid helper (fuservicemount3) performs the mount on its
+behalf. Servers use the service API in fuse_service.h; the service_hl.c and
+service_ll.c examples show the high- and low-level variants.
+
+The README.service-mount and README.service-mount-dev files in the source
+*doc* directory document this feature for administrators and filesystem
+authors respectively.
+
 ## Examples ##
 
 FUSE comes with several examples in the <a
diff --git a/doc/mount.fuse3.8 b/doc/mount.fuse3.8
index d55c96139d9f..b3c959aad63c 100644
--- a/doc/mount.fuse3.8
+++ b/doc/mount.fuse3.8
@@ -231,6 +231,23 @@ Switch to \fBUSER\fP and its primary group before launching the FUSE file system
 \fBdrop_privileges\fP
 Perform setup of the FUSE file descriptor and mounting the file system before launching the FUSE file system process. \fBmount.fuse3\fP requires privilege to do so, i.e. must be run as root or at least with \fBCAP_SYS_ADMIN\fP and \fBCAP_SETPCAP\fP. It will launch the file system process fully unprivileged, i.e. without \fBcapabilities\fP(7) and \fBprctl\fP(2) flags set up such that privileges can't be reacquired (e.g. via setuid or fscaps binaries). This reduces risk in the event of the FUSE file system process getting compromised by malicious file system data. Because the file system program is launched after privileges have been dropped, it and the libraries it links against must reside at a path the unprivileged process can resolve: every directory component must be searchable without elevated privileges.
 
+.SH SERVICE MOUNTS
+If libfuse was built with service mount support, \fBmount.fuse3\fP can mount
+filesystems whose server runs as a sandboxed systemd socket service instead of
+as a child of the mounting process. When you mount a type \fBfuse.\fIsubtype\fR
+(or \fBfuseblk.\fIsubtype\fR), \fBmount.fuse3\fP first checks for a service
+socket for that subtype. If one exists, the mount is handed to
+\fBfuservicemount3\fP(8) and performed by the already-running, isolated server;
+all arguments except \fB-t\fP \fItype\fR are forwarded to it.
+.PP
+If no service socket exists, \fBmount.fuse3\fP transparently falls back to the
+traditional behaviour and runs the filesystem server program directly, so
+filesystems that are not set up as services are unaffected. Some options that
+are incompatible with an already-running server (such as passing a pre-opened
+FUSE file descriptor, or \fBsetuid=USER\fP) also force the traditional path.
+.PP
+See the libfuse \fIREADME.service-mount\fP document for details on installing
+and using service-mounted filesystems.
 .SH FUSE MODULES (STACKING)
 Modules are filesystem stacking support to high level API. Filesystem modules can be built into libfuse or loaded from shared object
 .SS "iconv"
@@ -276,5 +293,6 @@ Debian GNU/Linux distribution.
 .SH SEE ALSO
 .BR fusermount3 (1)
 .BR fusermount (1)
+.BR fuservicemount3 (8)
 .BR mount (8)
 .BR fuse (4)

-- 
2.53.0

