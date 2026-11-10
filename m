From: Eric Davis <eric.davis@broadcom.com>
Date: Mon, 09 Nov 2026 20:00:40 -0800
Subject: [PATCH rdma-next v3 07/13] RDMA/core: job and job key objects
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-uet-ib-core-v3-7-3e7e7ffed2e9@broadcom.com>
References: <20261109-uet-ib-core-v3-0-3e7e7ffed2e9@broadcom.com>
In-Reply-To: <20261109-uet-ib-core-v3-0-3e7e7ffed2e9@broadcom.com>
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794283250; l=34252;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=vaeAAbJrv2Kls6HMt222qbmn9XCIjdvrXAz2X5ziImQ=;
 b=gVllQjIsA6aaZEx6zfSy5yyj7Pxmk7AA+nYoemjMRur+2YIM1WJt/uZZR6QYMzqW8+wWVKF0W
 cG4/60YC41dD06NJ37XJqwK8XzMXB36qFZfLhKi2dIP5cJBjMDNJe0K
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An unconnected transport demultiplexes incoming traffic on a JobID rather
than on a connection. Add two objects for it: a job, which owns that ID
and a table of peer addresses reached from its port, and a job key, which
ties a job to a protection domain and authorizes a queue pair to act
within it.

A job can be exported to a file descriptor and imported elsewhere, so an
unprivileged process can join a job that was set up for it.

Signed-off-by: Eric Davis <eric.davis@broadcom.com>
---
 drivers/infiniband/core/Makefile               |   3 +-
 drivers/infiniband/core/device.c               |  10 +
 drivers/infiniband/core/nldev.c                |   8 +
 drivers/infiniband/core/rdma_core.h            |   2 +
 drivers/infiniband/core/restrack.c             |   4 +
 drivers/infiniband/core/uverbs.h               |   6 +
 drivers/infiniband/core/uverbs_std_types_job.c | 644 +++++++++++++++++++++++++
 drivers/infiniband/core/uverbs_uapi.c          |   2 +
 drivers/infiniband/core/verbs.c                |  37 ++
 include/rdma/ib_verbs.h                        |  65 +++
 include/rdma/restrack.h                        |   8 +
 include/rdma/uverbs_ioctl.h                    |   2 +-
 include/uapi/rdma/ib_user_ioctl_cmds.h         |  77 +++
 13 files changed, 866 insertions(+), 2 deletions(-)

diff --git a/drivers/infiniband/core/Makefile b/drivers/infiniband/core/Makefile
index 47ef6b0afd29..f169c1bfa8b8 100644
--- a/drivers/infiniband/core/Makefile
+++ b/drivers/infiniband/core/Makefile
@@ -47,7 +47,8 @@ ib_uverbs-y :=			uverbs_main.o uverbs_cmd.o uverbs_marshall.o \
 				uverbs_std_types_async_fd.o \
 				uverbs_std_types_srq.o \
 				uverbs_std_types_wq.o \
-				uverbs_std_types_qp.o
+				uverbs_std_types_qp.o \
+				uverbs_std_types_job.o
 
 ib_uverbs_support-y :=		rdma_core.o \
 				ucaps.o \
diff --git a/drivers/infiniband/core/device.c b/drivers/infiniband/core/device.c
index 8b1563de4726..cf2a59afcf76 100644
--- a/drivers/infiniband/core/device.c
+++ b/drivers/infiniband/core/device.c
@@ -2915,6 +2915,14 @@ void ib_set_device_ops(struct ib_device *dev, const struct ib_device_ops *ops)
 	SET_DEVICE_OP(dev_ops, counter_unbind_qp);
 	SET_DEVICE_OP(dev_ops, counter_update_stats);
 	SET_DEVICE_OP(dev_ops, create_ah);
+	SET_DEVICE_OP(dev_ops, alloc_job);
+	SET_DEVICE_OP(dev_ops, dealloc_job);
+	SET_DEVICE_OP(dev_ops, query_job);
+	SET_DEVICE_OP(dev_ops, job_addr_insert);
+	SET_DEVICE_OP(dev_ops, job_addr_remove);
+	SET_DEVICE_OP(dev_ops, job_addr_query);
+	SET_DEVICE_OP(dev_ops, create_jkey);
+	SET_DEVICE_OP(dev_ops, destroy_jkey);
 	SET_DEVICE_OP(dev_ops, create_counters);
 	SET_DEVICE_OP(dev_ops, create_cq);
 	SET_DEVICE_OP(dev_ops, create_comp_cntr);
@@ -3031,6 +3039,8 @@ void ib_set_device_ops(struct ib_device *dev, const struct ib_device_ops *ops)
 
 	SET_OBJ_SIZE(dev_ops, ib_ah);
 	SET_OBJ_SIZE(dev_ops, ib_counters);
+	SET_OBJ_SIZE(dev_ops, ib_job);
+	SET_OBJ_SIZE(dev_ops, ib_jkey);
 	SET_OBJ_SIZE(dev_ops, ib_cq);
 	SET_OBJ_SIZE(dev_ops, ib_comp_cntr);
 	SET_OBJ_SIZE(dev_ops, ib_dmah);
diff --git a/drivers/infiniband/core/nldev.c b/drivers/infiniband/core/nldev.c
index 91b7be84b15f..d1df9c6eecae 100644
--- a/drivers/infiniband/core/nldev.c
+++ b/drivers/infiniband/core/nldev.c
@@ -454,6 +454,8 @@ static int fill_res_info(struct sk_buff *msg, struct ib_device *device,
 		[RDMA_RESTRACK_CTX] = "ctx",
 		[RDMA_RESTRACK_SRQ] = "srq",
 		[RDMA_RESTRACK_COMP_CNTR] = "comp_cntr",
+		[RDMA_RESTRACK_JOB] = "job",
+		[RDMA_RESTRACK_JKEY] = "jkey",
 	};
 
 	struct ib_comp_cntr_caps comp_cntr_caps = {};
@@ -494,6 +496,12 @@ static int fill_res_info(struct sk_buff *msg, struct ib_device *device,
 		case RDMA_RESTRACK_COMP_CNTR:
 			max = comp_cntr_caps.max_counters;
 			break;
+		case RDMA_RESTRACK_JOB:
+			max = device->attrs.max_job_ids;
+			break;
+		case RDMA_RESTRACK_JKEY:
+			max = device->attrs.max_job_keys;
+			break;
 		default:
 			max = 0;
 		}
diff --git a/drivers/infiniband/core/rdma_core.h b/drivers/infiniband/core/rdma_core.h
index 9de14e625dd3..523a6f7d4439 100644
--- a/drivers/infiniband/core/rdma_core.h
+++ b/drivers/infiniband/core/rdma_core.h
@@ -164,6 +164,8 @@ void uverbs_user_mmap_disassociate(struct ib_uverbs_file *ufile);
 
 extern const struct uapi_definition uverbs_def_obj_async_fd[];
 extern const struct uapi_definition uverbs_def_obj_counters[];
+extern const struct uapi_definition uverbs_def_obj_job[];
+extern const struct uapi_definition uverbs_def_obj_jkey[];
 extern const struct uapi_definition uverbs_def_obj_comp_cntr[];
 extern const struct uapi_definition uverbs_def_obj_cq[];
 extern const struct uapi_definition uverbs_def_obj_device[];
diff --git a/drivers/infiniband/core/restrack.c b/drivers/infiniband/core/restrack.c
index a75af79adf2c..fa5b78e78331 100644
--- a/drivers/infiniband/core/restrack.c
+++ b/drivers/infiniband/core/restrack.c
@@ -106,6 +106,10 @@ static struct ib_device *res_to_dev(struct rdma_restrack_entry *res)
 		return container_of(res, struct ib_dmah, res)->device;
 	case RDMA_RESTRACK_COMP_CNTR:
 		return container_of(res, struct ib_comp_cntr, res)->device;
+	case RDMA_RESTRACK_JOB:
+		return container_of(res, struct ib_job, res)->device;
+	case RDMA_RESTRACK_JKEY:
+		return container_of(res, struct ib_jkey, res)->device;
 	default:
 		WARN_ONCE(true, "Wrong resource tracking type %u\n", res->type);
 		return NULL;
diff --git a/drivers/infiniband/core/uverbs.h b/drivers/infiniband/core/uverbs.h
index 2160985f18e9..e179cd924eba 100644
--- a/drivers/infiniband/core/uverbs.h
+++ b/drivers/infiniband/core/uverbs.h
@@ -183,6 +183,12 @@ struct ib_uxrcd_object {
 	atomic_t		refcnt;
 };
 
+struct ib_ujob_object {
+	struct ib_uobject	uobject;
+	/* job keys created through this handle */
+	atomic_t		refcnt;
+};
+
 struct ib_usrq_object {
 	struct ib_uevent_object	uevent;
 	struct ib_uxrcd_object *uxrcd;
diff --git a/drivers/infiniband/core/uverbs_std_types_job.c b/drivers/infiniband/core/uverbs_std_types_job.c
new file mode 100644
index 000000000000..4f3b776740eb
--- /dev/null
+++ b/drivers/infiniband/core/uverbs_std_types_job.c
@@ -0,0 +1,644 @@
+// SPDX-License-Identifier: GPL-2.0-only OR Linux-OpenIB
+
+/*
+ * Copyright (c) 2026 Broadcom. All rights reserved. The term Broadcom
+ * refers to Broadcom Inc. and/or its subsidiaries.
+ */
+
+/*
+ * The job object of a reliable unordered transport.
+ */
+
+#include <linux/file.h>
+
+#include <rdma/ib_marshall.h>
+#include <rdma/uverbs_std_types.h>
+
+#include "rdma_core.h"
+#include "restrack.h"
+#include "uverbs.h"
+
+static void ib_job_release(struct kref *ref)
+{
+	struct ib_job *job = container_of(ref, struct ib_job, ref);
+
+	rdma_restrack_del(&job->res);
+	job->device->ops.dealloc_job(job);
+	kfree(job);
+}
+
+/* An exported job. The descriptor belongs to the context that exported it,
+ * so it stops naming the job once that context is closed or the device is
+ * removed. A context that imported the job holds its own reference.
+ */
+struct ib_ujob_fd_object {
+	struct ib_uobject	uobject;
+	/* serializes an import against the descriptor's destroy */
+	spinlock_t		lock;
+	struct ib_job		*job;
+};
+
+static const struct file_operations ib_job_fops = {
+	.owner = THIS_MODULE,
+	.release = uverbs_uobject_fd_release,
+};
+
+static void uverbs_job_fd_destroy_uobj(struct ib_uobject *uobj,
+				       enum rdma_remove_reason why)
+{
+	struct ib_ujob_fd_object *ujf =
+		container_of(uobj, struct ib_ujob_fd_object, uobject);
+	struct ib_job *job;
+
+	spin_lock(&ujf->lock);
+	job = ujf->job;
+	ujf->job = NULL;
+	spin_unlock(&ujf->lock);
+
+	if (job)
+		kref_put(&job->ref, ib_job_release);
+}
+
+/* Take a reference on the job an exported descriptor names */
+static int ib_job_get_from_fd(int fd, struct ib_device *ib_dev,
+			      struct ib_job **job)
+{
+	CLASS(fd, f)(fd);
+	struct ib_ujob_fd_object *ujf;
+	int ret = 0;
+
+	if (fd_empty(f))
+		return -EBADF;
+
+	/* refuse anything that is not an exported job */
+	if (fd_file(f)->f_op != &ib_job_fops)
+		return -EINVAL;
+
+	ujf = container_of((struct ib_uobject *)fd_file(f)->private_data,
+			   struct ib_ujob_fd_object, uobject);
+
+	spin_lock(&ujf->lock);
+	*job = ujf->job;
+	/* a descriptor whose context is gone names nothing, even when a
+	 * driver failure skipped its destroy and left the job set
+	 */
+	if (!*job || !READ_ONCE(ujf->uobject.context))
+		ret = -EIO;
+	/* a handle names a job on the device it was allocated on */
+	else if ((*job)->device != ib_dev)
+		ret = -EINVAL;
+	/* an imported job holds one reference */
+	else
+		kref_get(&(*job)->ref);
+	spin_unlock(&ujf->lock);
+
+	return ret;
+}
+
+static int UVERBS_HANDLER(UVERBS_METHOD_JOB_EXPORT)(
+	struct uverbs_attr_bundle *attrs)
+{
+	struct ib_job *job =
+		uverbs_attr_get_obj(attrs, UVERBS_ATTR_EXPORT_JOB_HANDLE);
+	struct ib_uobject *uobj =
+		uverbs_attr_get_uobject(attrs, UVERBS_ATTR_EXPORT_JOB_FD);
+	struct ib_ujob_fd_object *ujf =
+		container_of(uobj, struct ib_ujob_fd_object, uobject);
+
+	spin_lock_init(&ujf->lock);
+
+	/* an exported job is a descriptor holding one reference */
+	kref_get(&job->ref);
+	ujf->job = job;
+	uverbs_finalize_uobj_create(attrs, UVERBS_ATTR_EXPORT_JOB_FD);
+
+	return 0;
+}
+
+static int UVERBS_HANDLER(UVERBS_METHOD_JOB_IMPORT)(
+	struct uverbs_attr_bundle *attrs)
+{
+	struct ib_uobject *uobj =
+		uverbs_attr_get_uobject(attrs, UVERBS_ATTR_IMPORT_JOB_HANDLE);
+	struct ib_device *ib_dev = attrs->context->device;
+	struct ib_job *job;
+	int fd, ret;
+
+	ret = uverbs_get_raw_fd(&fd, attrs, UVERBS_ATTR_IMPORT_JOB_FD);
+	if (ret)
+		return ret;
+
+	ret = ib_job_get_from_fd(fd, ib_dev, &job);
+	if (ret)
+		return ret;
+
+	uobj->object = job;
+	uverbs_finalize_uobj_create(attrs, UVERBS_ATTR_IMPORT_JOB_HANDLE);
+
+	return 0;
+}
+
+static int uverbs_free_job(struct ib_uobject *uobject,
+			   enum rdma_remove_reason why,
+			   struct uverbs_attr_bundle *attrs)
+{
+	struct ib_ujob_object *ujob =
+		container_of(uobject, struct ib_ujob_object, uobject);
+	struct ib_job *job = uobject->object;
+
+	/* don't free if there are still references to this job */
+	if (atomic_read(&ujob->refcnt))
+		return -EBUSY;
+
+	kref_put(&job->ref, ib_job_release);
+
+	return 0;
+}
+
+static int UVERBS_HANDLER(UVERBS_METHOD_JOB_ALLOC)(
+	struct uverbs_attr_bundle *attrs)
+{
+	struct ib_uobject *uobj =
+		uverbs_attr_get_uobject(attrs, UVERBS_ATTR_ALLOC_JOB_HANDLE);
+	struct ib_device *ib_dev = attrs->context->device;
+	struct ib_job_attr attr = {};
+	struct ib_job *job;
+	int ret;
+
+	if (!ib_dev->ops.alloc_job)
+		return -EOPNOTSUPP;
+
+	/* A JobID names a domain across the fabric rather than anything
+	 * local to this process, so claiming one is an administrative act.
+	 */
+	if (!rdma_uattrs_has_raw_cap(attrs))
+		return -EPERM;
+
+	ret = uverbs_copy_from(&attr.job_id, attrs, UVERBS_ATTR_ALLOC_JOB_ID);
+	if (ret)
+		return ret;
+
+	ret = uverbs_copy_from(&attr.max_addr_entries, attrs,
+			       UVERBS_ATTR_ALLOC_JOB_MAX_ADDR_ENTRIES);
+	if (ret)
+		return ret;
+
+	/* The rest are optional and an absent attribute reads as -ENOENT
+	 * which IS_UVERBS_COPY_ERR() checks.
+	 */
+	ret = uverbs_copy_from(&attr.port_num, attrs,
+			       UVERBS_ATTR_ALLOC_JOB_PORT_NUM);
+	if (IS_UVERBS_COPY_ERR(ret))
+		return ret;
+
+	ret = uverbs_copy_from(&attr.sgid_index, attrs,
+			       UVERBS_ATTR_ALLOC_JOB_SGID_INDEX);
+	if (IS_UVERBS_COPY_ERR(ret))
+		return ret;
+
+	/* the table is sized once, every index is checked against it */
+	if (!attr.max_addr_entries ||
+	    attr.max_addr_entries > ib_dev->attrs.max_addr_entries)
+		return -EINVAL;
+
+	/* the port carries the job's traffic, so it has to be one we have */
+	if (!attr.port_num)
+		attr.port_num = rdma_start_port(ib_dev);
+	if (!rdma_is_port_valid(ib_dev, attr.port_num))
+		return -EINVAL;
+
+	if (attr.sgid_index >=
+	    ib_dev->port_data[attr.port_num].immutable.gid_tbl_len)
+		return -EINVAL;
+
+	job = rdma_zalloc_drv_obj(ib_dev, ib_job);
+	if (!job)
+		return -ENOMEM;
+
+	job->device = ib_dev;
+	job->job_id = attr.job_id;
+	job->max_addr_entries = attr.max_addr_entries;
+	job->port_num = attr.port_num;
+	kref_init(&job->ref);
+	uobj->object = job;
+
+	rdma_restrack_new(&job->res, RDMA_RESTRACK_JOB);
+	rdma_restrack_set_name(&job->res, NULL);
+
+	ret = ib_dev->ops.alloc_job(job, &attr, attrs);
+	if (ret)
+		goto err_free;
+
+	rdma_restrack_add(&job->res);
+	uverbs_finalize_uobj_create(attrs, UVERBS_ATTR_ALLOC_JOB_HANDLE);
+
+	return 0;
+
+err_free:
+	rdma_restrack_put(&job->res);
+	kfree(job);
+	return ret;
+}
+
+static int UVERBS_HANDLER(UVERBS_METHOD_JOB_QUERY)(
+	struct uverbs_attr_bundle *attrs)
+{
+	struct ib_job *job =
+		uverbs_attr_get_obj(attrs, UVERBS_ATTR_QUERY_JOB_HANDLE);
+	struct ib_job_attr attr = {};
+	int ret;
+
+	if (!job->device->ops.query_job)
+		return -EOPNOTSUPP;
+
+	ret = job->device->ops.query_job(job, &attr);
+	if (ret)
+		return ret;
+
+	ret = uverbs_copy_to(attrs, UVERBS_ATTR_QUERY_JOB_ID, &attr.job_id,
+			     sizeof(attr.job_id));
+	if (ret)
+		return ret;
+
+	ret = uverbs_copy_to(attrs, UVERBS_ATTR_QUERY_JOB_MAX_ADDR_ENTRIES,
+			     &attr.max_addr_entries,
+			     sizeof(attr.max_addr_entries));
+	if (ret)
+		return ret;
+
+	ret = uverbs_copy_to(attrs, UVERBS_ATTR_QUERY_JOB_PORT_NUM,
+			     &attr.port_num, sizeof(attr.port_num));
+	if (ret)
+		return ret;
+
+	return uverbs_copy_to(attrs, UVERBS_ATTR_QUERY_JOB_SGID_INDEX,
+			      &attr.sgid_index, sizeof(attr.sgid_index));
+}
+
+static int UVERBS_HANDLER(UVERBS_METHOD_JOB_ADDR_INSERT)(
+	struct uverbs_attr_bundle *attrs)
+{
+	struct ib_job *job = uverbs_attr_get_obj(
+		attrs, UVERBS_ATTR_JOB_ADDR_INSERT_HANDLE);
+	struct ib_uverbs_ah_attr_ex uah;
+	struct rdma_ah_attr_ex ah_attr = {};
+	u32 index;
+	int ret;
+
+	if (!job->device->ops.job_addr_insert)
+		return -EOPNOTSUPP;
+
+	/* An address table entry names a peer on the fabric for every process
+	 * in the job, so writing one redirects their traffic. An address
+	 * handle, by contrast, serves only the process that made it.
+	 */
+	if (!rdma_uattrs_has_raw_cap(attrs))
+		return -EPERM;
+
+	ret = uverbs_copy_from(&index, attrs,
+			       UVERBS_ATTR_JOB_ADDR_INSERT_INDEX);
+	if (ret)
+		return ret;
+
+	ret = uverbs_copy_from_or_zero(&uah, attrs,
+				       UVERBS_ATTR_JOB_ADDR_INSERT_AH_ATTR_EX);
+	if (ret)
+		return ret;
+
+	if (index >= job->max_addr_entries)
+		return -EINVAL;
+
+	ret = copy_ah_attr_from_uverbs_ah(job->device, &ah_attr.ah_attr,
+					  &uah.ah_attr);
+	if (ret)
+		return ret;
+
+	/* a peer is reached from the job's own port */
+	if (rdma_ah_get_port_num(&ah_attr.ah_attr) != job->port_num)
+		return -EINVAL;
+
+	if (uah.remote_qpn & IB_UVERBS_QPN_UET_RESERVED_MASK)
+		return -EINVAL;
+
+	ah_attr.remote_qpn = uah.remote_qpn;
+
+	return rdma_job_addr_insert(job, index, &ah_attr);
+}
+
+static int UVERBS_HANDLER(UVERBS_METHOD_JOB_ADDR_REMOVE)(
+	struct uverbs_attr_bundle *attrs)
+{
+	struct ib_job *job = uverbs_attr_get_obj(
+		attrs, UVERBS_ATTR_JOB_ADDR_REMOVE_HANDLE);
+	u32 index;
+	int ret;
+
+	if (!job->device->ops.job_addr_remove)
+		return -EOPNOTSUPP;
+
+	if (!rdma_uattrs_has_raw_cap(attrs))
+		return -EPERM;
+
+	ret = uverbs_copy_from(&index, attrs,
+			       UVERBS_ATTR_JOB_ADDR_REMOVE_INDEX);
+	if (ret)
+		return ret;
+
+	if (index >= job->max_addr_entries)
+		return -EINVAL;
+
+	return job->device->ops.job_addr_remove(job, index);
+}
+
+static int UVERBS_HANDLER(UVERBS_METHOD_JOB_ADDR_QUERY)(
+	struct uverbs_attr_bundle *attrs)
+{
+	struct ib_job *job = uverbs_attr_get_obj(
+		attrs, UVERBS_ATTR_JOB_ADDR_QUERY_HANDLE);
+	struct ib_uverbs_ah_attr_ex uah = {};
+	struct rdma_ah_attr_ex ah_attr = {};
+	u32 index;
+	int ret;
+
+	if (!job->device->ops.job_addr_query)
+		return -EOPNOTSUPP;
+
+	ret = uverbs_copy_from(&index, attrs,
+			       UVERBS_ATTR_JOB_ADDR_QUERY_INDEX);
+	if (ret)
+		return ret;
+
+	if (index >= job->max_addr_entries)
+		return -EINVAL;
+
+	ret = job->device->ops.job_addr_query(job, index, &ah_attr);
+	if (ret) {
+		rdma_destroy_ah_attr(&ah_attr.ah_attr);
+		return ret;
+	}
+
+	ib_copy_ah_attr_to_user(job->device, &uah.ah_attr, &ah_attr.ah_attr);
+	uah.remote_qpn = ah_attr.remote_qpn;
+	rdma_destroy_ah_attr(&ah_attr.ah_attr);
+
+	return uverbs_copy_to_struct_or_zero(
+		attrs, UVERBS_ATTR_JOB_ADDR_QUERY_AH_ATTR_EX, &uah, sizeof(uah));
+}
+
+DECLARE_UVERBS_NAMED_METHOD(
+	UVERBS_METHOD_JOB_ADDR_INSERT,
+	UVERBS_ATTR_IDR(UVERBS_ATTR_JOB_ADDR_INSERT_HANDLE,
+			UVERBS_OBJECT_JOB,
+			UVERBS_ACCESS_READ,
+			UA_MANDATORY),
+	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_JOB_ADDR_INSERT_INDEX,
+			   UVERBS_ATTR_TYPE(u32),
+			   UA_MANDATORY),
+	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_JOB_ADDR_INSERT_AH_ATTR_EX,
+			   UVERBS_ATTR_STRUCT(struct ib_uverbs_ah_attr_ex,
+					      remote_qpn),
+			   UA_MANDATORY));
+
+DECLARE_UVERBS_NAMED_METHOD(
+	UVERBS_METHOD_JOB_ADDR_REMOVE,
+	UVERBS_ATTR_IDR(UVERBS_ATTR_JOB_ADDR_REMOVE_HANDLE,
+			UVERBS_OBJECT_JOB,
+			UVERBS_ACCESS_READ,
+			UA_MANDATORY),
+	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_JOB_ADDR_REMOVE_INDEX,
+			   UVERBS_ATTR_TYPE(u32),
+			   UA_MANDATORY));
+
+DECLARE_UVERBS_NAMED_METHOD(
+	UVERBS_METHOD_JOB_ADDR_QUERY,
+	UVERBS_ATTR_IDR(UVERBS_ATTR_JOB_ADDR_QUERY_HANDLE,
+			UVERBS_OBJECT_JOB,
+			UVERBS_ACCESS_READ,
+			UA_MANDATORY),
+	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_JOB_ADDR_QUERY_INDEX,
+			   UVERBS_ATTR_TYPE(u32),
+			   UA_MANDATORY),
+	UVERBS_ATTR_PTR_OUT(UVERBS_ATTR_JOB_ADDR_QUERY_AH_ATTR_EX,
+			    UVERBS_ATTR_STRUCT(struct ib_uverbs_ah_attr_ex,
+					       remote_qpn),
+			    UA_MANDATORY));
+
+DECLARE_UVERBS_NAMED_METHOD(
+	UVERBS_METHOD_JOB_ALLOC,
+	UVERBS_ATTR_IDR(UVERBS_ATTR_ALLOC_JOB_HANDLE,
+			UVERBS_OBJECT_JOB,
+			UVERBS_ACCESS_NEW,
+			UA_MANDATORY),
+	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_ALLOC_JOB_ID,
+			   UVERBS_ATTR_TYPE(u32),
+			   UA_MANDATORY),
+	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_ALLOC_JOB_MAX_ADDR_ENTRIES,
+			   UVERBS_ATTR_TYPE(u32),
+			   UA_MANDATORY),
+	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_ALLOC_JOB_PORT_NUM,
+			   UVERBS_ATTR_TYPE(u32),
+			   UA_OPTIONAL),
+	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_ALLOC_JOB_SGID_INDEX,
+			   UVERBS_ATTR_TYPE(u8),
+			   UA_OPTIONAL),
+	UVERBS_ATTR_UHW());
+
+DECLARE_UVERBS_NAMED_METHOD(
+	UVERBS_METHOD_JOB_EXPORT,
+	UVERBS_ATTR_IDR(UVERBS_ATTR_EXPORT_JOB_HANDLE,
+			UVERBS_OBJECT_JOB,
+			UVERBS_ACCESS_READ,
+			UA_MANDATORY),
+	UVERBS_ATTR_FD(UVERBS_ATTR_EXPORT_JOB_FD,
+		       UVERBS_OBJECT_JOB_FD,
+		       UVERBS_ACCESS_NEW,
+		       UA_MANDATORY));
+
+DECLARE_UVERBS_NAMED_METHOD(
+	UVERBS_METHOD_JOB_IMPORT,
+	UVERBS_ATTR_IDR(UVERBS_ATTR_IMPORT_JOB_HANDLE,
+			UVERBS_OBJECT_JOB,
+			UVERBS_ACCESS_NEW,
+			UA_MANDATORY),
+	UVERBS_ATTR_RAW_FD(UVERBS_ATTR_IMPORT_JOB_FD,
+			   UA_MANDATORY));
+
+DECLARE_UVERBS_NAMED_METHOD_DESTROY(
+	UVERBS_METHOD_JOB_DEALLOC,
+	UVERBS_ATTR_IDR(UVERBS_ATTR_DEALLOC_JOB_HANDLE,
+			UVERBS_OBJECT_JOB,
+			UVERBS_ACCESS_DESTROY,
+			UA_MANDATORY));
+
+DECLARE_UVERBS_NAMED_METHOD(
+	UVERBS_METHOD_JOB_QUERY,
+	UVERBS_ATTR_IDR(UVERBS_ATTR_QUERY_JOB_HANDLE,
+			UVERBS_OBJECT_JOB,
+			UVERBS_ACCESS_READ,
+			UA_MANDATORY),
+	UVERBS_ATTR_PTR_OUT(UVERBS_ATTR_QUERY_JOB_ID,
+			    UVERBS_ATTR_TYPE(u32),
+			    UA_MANDATORY),
+	UVERBS_ATTR_PTR_OUT(UVERBS_ATTR_QUERY_JOB_MAX_ADDR_ENTRIES,
+			    UVERBS_ATTR_TYPE(u32),
+			    UA_MANDATORY),
+	UVERBS_ATTR_PTR_OUT(UVERBS_ATTR_QUERY_JOB_PORT_NUM,
+			    UVERBS_ATTR_TYPE(u32),
+			    UA_MANDATORY),
+	UVERBS_ATTR_PTR_OUT(UVERBS_ATTR_QUERY_JOB_SGID_INDEX,
+			    UVERBS_ATTR_TYPE(u8),
+			    UA_MANDATORY));
+
+DECLARE_UVERBS_NAMED_OBJECT(UVERBS_OBJECT_JOB,
+			    UVERBS_TYPE_ALLOC_IDR_SZ(
+				    sizeof(struct ib_ujob_object),
+				    uverbs_free_job),
+			    &UVERBS_METHOD(UVERBS_METHOD_JOB_ALLOC),
+			    &UVERBS_METHOD(UVERBS_METHOD_JOB_DEALLOC),
+			    &UVERBS_METHOD(UVERBS_METHOD_JOB_QUERY),
+			    &UVERBS_METHOD(UVERBS_METHOD_JOB_ADDR_INSERT),
+			    &UVERBS_METHOD(UVERBS_METHOD_JOB_ADDR_REMOVE),
+			    &UVERBS_METHOD(UVERBS_METHOD_JOB_ADDR_QUERY),
+			    &UVERBS_METHOD(UVERBS_METHOD_JOB_EXPORT),
+			    &UVERBS_METHOD(UVERBS_METHOD_JOB_IMPORT));
+
+DECLARE_UVERBS_NAMED_OBJECT(UVERBS_OBJECT_JOB_FD,
+			    UVERBS_TYPE_ALLOC_FD(
+				    sizeof(struct ib_ujob_fd_object),
+				    uverbs_job_fd_destroy_uobj,
+				    &ib_job_fops, "[ib_job]", O_RDWR));
+
+const struct uapi_definition uverbs_def_obj_job[] = {
+	UAPI_DEF_CHAIN_OBJ_TREE_NAMED(UVERBS_OBJECT_JOB,
+				      UAPI_DEF_OBJ_NEEDS_FN(dealloc_job)),
+	UAPI_DEF_CHAIN_OBJ_TREE_NAMED(UVERBS_OBJECT_JOB_FD,
+				      UAPI_DEF_OBJ_NEEDS_FN(dealloc_job)),
+	{}
+};
+
+/* drop what JKEY_CREATE took on the key's job and PD */
+static void ib_jkey_put_refs(struct ib_jkey *jkey)
+{
+	atomic_dec(&jkey->pd->usecnt);
+	atomic_dec(&container_of(jkey->job_uobject, struct ib_ujob_object,
+				 uobject)->refcnt);
+	kref_put(&jkey->job->ref, ib_job_release);
+}
+
+static int uverbs_free_jkey(struct ib_uobject *uobject,
+			    enum rdma_remove_reason why,
+			    struct uverbs_attr_bundle *attrs)
+{
+	struct ib_jkey *jkey = uobject->object;
+	int ret;
+
+	/* queue pairs created with this key still hold it */
+	if (atomic_read(&jkey->usecnt))
+		return -EBUSY;
+
+	rdma_restrack_begin_del(&jkey->res);
+
+	ret = jkey->device->ops.destroy_jkey(jkey, attrs);
+	if (ret) {
+		rdma_restrack_abort_del(&jkey->res);
+		return ret;
+	}
+
+	rdma_restrack_commit_del(&jkey->res);
+
+	ib_jkey_put_refs(jkey);
+	kfree(jkey);
+
+	return 0;
+}
+
+static int UVERBS_HANDLER(UVERBS_METHOD_JKEY_CREATE)(
+	struct uverbs_attr_bundle *attrs)
+{
+	struct ib_uobject *uobj =
+		uverbs_attr_get_uobject(attrs, UVERBS_ATTR_CREATE_JKEY_HANDLE);
+	struct ib_uobject *job_uobj = uverbs_attr_get_uobject(
+		attrs, UVERBS_ATTR_CREATE_JKEY_JOB_HANDLE);
+	struct ib_pd *pd =
+		uverbs_attr_get_obj(attrs, UVERBS_ATTR_CREATE_JKEY_PD_HANDLE);
+	struct ib_job *job;
+	struct ib_device *ib_dev = attrs->context->device;
+	struct ib_jkey *jkey;
+	int ret;
+
+	if (!ib_dev->ops.create_jkey)
+		return -EOPNOTSUPP;
+
+	job = job_uobj->object;
+
+	jkey = rdma_zalloc_drv_obj(ib_dev, ib_jkey);
+	if (!jkey)
+		return -ENOMEM;
+
+	jkey->device = ib_dev;
+	jkey->uobject = uobj;
+	jkey->job = job;
+	jkey->job_uobject = job_uobj;
+	jkey->pd = pd;
+	atomic_set(&jkey->usecnt, 0);
+	uobj->object = jkey;
+
+	rdma_restrack_new(&jkey->res, RDMA_RESTRACK_JKEY);
+	rdma_restrack_set_name(&jkey->res, NULL);
+
+	ret = ib_dev->ops.create_jkey(jkey, attrs);
+	if (ret) {
+		rdma_restrack_put(&jkey->res);
+		kfree(jkey);
+		return ret;
+	}
+
+	rdma_restrack_add(&jkey->res);
+
+	/* the job and PD cannot be freed while this key references them */
+	kref_get(&job->ref);
+	atomic_inc(&container_of(job_uobj, struct ib_ujob_object,
+				 uobject)->refcnt);
+	atomic_inc(&pd->usecnt);
+	uverbs_finalize_uobj_create(attrs, UVERBS_ATTR_CREATE_JKEY_HANDLE);
+
+	return uverbs_copy_to(attrs, UVERBS_ATTR_CREATE_JKEY_JKEY, &jkey->jkey,
+			      sizeof(jkey->jkey));
+}
+
+DECLARE_UVERBS_NAMED_METHOD(
+	UVERBS_METHOD_JKEY_CREATE,
+	UVERBS_ATTR_IDR(UVERBS_ATTR_CREATE_JKEY_HANDLE,
+			UVERBS_OBJECT_JKEY,
+			UVERBS_ACCESS_NEW,
+			UA_MANDATORY),
+	UVERBS_ATTR_IDR(UVERBS_ATTR_CREATE_JKEY_JOB_HANDLE,
+			UVERBS_OBJECT_JOB,
+			UVERBS_ACCESS_READ,
+			UA_MANDATORY),
+	UVERBS_ATTR_IDR(UVERBS_ATTR_CREATE_JKEY_PD_HANDLE,
+			UVERBS_OBJECT_PD,
+			UVERBS_ACCESS_READ,
+			UA_MANDATORY),
+	UVERBS_ATTR_PTR_OUT(UVERBS_ATTR_CREATE_JKEY_JKEY,
+			    UVERBS_ATTR_TYPE(u32),
+			    UA_MANDATORY),
+	UVERBS_ATTR_UHW());
+
+DECLARE_UVERBS_NAMED_METHOD_DESTROY(
+	UVERBS_METHOD_JKEY_DESTROY,
+	UVERBS_ATTR_IDR(UVERBS_ATTR_DESTROY_JKEY_HANDLE,
+			UVERBS_OBJECT_JKEY,
+			UVERBS_ACCESS_DESTROY,
+			UA_MANDATORY));
+
+DECLARE_UVERBS_NAMED_OBJECT(UVERBS_OBJECT_JKEY,
+			    UVERBS_TYPE_ALLOC_IDR(uverbs_free_jkey),
+			    &UVERBS_METHOD(UVERBS_METHOD_JKEY_CREATE),
+			    &UVERBS_METHOD(UVERBS_METHOD_JKEY_DESTROY));
+
+const struct uapi_definition uverbs_def_obj_jkey[] = {
+	UAPI_DEF_CHAIN_OBJ_TREE_NAMED(UVERBS_OBJECT_JKEY,
+				      UAPI_DEF_OBJ_NEEDS_FN(destroy_jkey)),
+	{}
+};
diff --git a/drivers/infiniband/core/uverbs_uapi.c b/drivers/infiniband/core/uverbs_uapi.c
index b67db3790f03..ee84be3061ea 100644
--- a/drivers/infiniband/core/uverbs_uapi.c
+++ b/drivers/infiniband/core/uverbs_uapi.c
@@ -636,6 +636,8 @@ static const struct uapi_definition uverbs_core_api[] = {
 	UAPI_DEF_CHAIN(uverbs_def_obj_dmah),
 	UAPI_DEF_CHAIN(uverbs_def_obj_flow_action),
 	UAPI_DEF_CHAIN(uverbs_def_obj_intf),
+	UAPI_DEF_CHAIN(uverbs_def_obj_job),
+	UAPI_DEF_CHAIN(uverbs_def_obj_jkey),
 	UAPI_DEF_CHAIN(uverbs_def_obj_mr),
 	UAPI_DEF_CHAIN(uverbs_def_obj_qp),
 	UAPI_DEF_CHAIN(uverbs_def_obj_srq),
diff --git a/drivers/infiniband/core/verbs.c b/drivers/infiniband/core/verbs.c
index 7e3cfebebf75..09b247462e65 100644
--- a/drivers/infiniband/core/verbs.c
+++ b/drivers/infiniband/core/verbs.c
@@ -690,6 +690,43 @@ struct ib_ah *rdma_create_user_ah(struct ib_pd *pd,
 }
 EXPORT_SYMBOL(rdma_create_user_ah);
 
+/**
+ * rdma_job_addr_insert - Insert a peer into a job's address table
+ * @job: The job.
+ * @index: The entry in the job's address table.
+ * @ah_attr: The peer's address and queue pair.
+ *
+ * The address is resolved as rdma_create_user_ah() resolves an address
+ * handle's: the source GID attribute is filled in, and for an Ethernet
+ * address so is the destination MAC.
+ *
+ * Return: 0 on success, or a negative errno.
+ */
+int rdma_job_addr_insert(struct ib_job *job, u32 index,
+			 struct rdma_ah_attr_ex *ah_attr)
+{
+	struct rdma_ah_attr *attr = &ah_attr->ah_attr;
+	const struct ib_gid_attr *old_sgid_attr;
+	int ret;
+
+	ret = rdma_fill_sgid_attr(job->device, attr, &old_sgid_attr);
+	if (ret)
+		return ret;
+
+	if (attr->type == RDMA_AH_ATTR_TYPE_ROCE) {
+		ret = ib_resolve_eth_dmac(job->device, attr);
+		if (ret)
+			goto out;
+	}
+
+	ret = job->device->ops.job_addr_insert(job, index, ah_attr);
+
+out:
+	rdma_unfill_sgid_attr(attr, old_sgid_attr);
+	return ret;
+}
+EXPORT_SYMBOL(rdma_job_addr_insert);
+
 int ib_get_rdma_header_version(const union rdma_network_hdr *hdr)
 {
 	const struct iphdr *ip4h = (struct iphdr *)&hdr->roce4grh;
diff --git a/include/rdma/ib_verbs.h b/include/rdma/ib_verbs.h
index 003b70424429..ce6707160a12 100644
--- a/include/rdma/ib_verbs.h
+++ b/include/rdma/ib_verbs.h
@@ -2496,6 +2496,43 @@ struct ib_counters {
 	atomic_t	usecnt;
 };
 
+struct ib_job_attr {
+	u32			job_id;
+	u32			max_addr_entries;
+	u32			port_num;
+	u8			sgid_index;
+};
+
+/* A job is a receive-side demultiplexing domain of an unconnected transport.
+ * A JobID names it on the wire, memory regions bind to it, and job keys
+ * authorize queue pairs within it.
+ */
+struct ib_job {
+	struct ib_device	*device;
+	/* the allocating and importing handles, exports, and job keys */
+	struct kref		ref;
+	u32			job_id;
+	/* entries in the address table, every index is below it */
+	u32			max_addr_entries;
+	/* the port the job's traffic uses, and every entry's port */
+	u32			port_num;
+	struct rdma_restrack_entry res;
+};
+
+/* A job key ties a job to a PD and authorizes a queue pair to act within a
+ * job. It holds a reference to its job and PD.
+ */
+struct ib_jkey {
+	struct ib_device	*device;
+	struct ib_uobject	*uobject;
+	struct ib_job		*job;
+	struct ib_uobject	*job_uobject;
+	struct ib_pd		*pd;
+	u32			jkey;
+	atomic_t		usecnt;
+	struct rdma_restrack_entry res;
+};
+
 /* what a queue pair of a given type guarantees (query_qp_semantics) */
 struct ib_qp_semantics {
 	u32	comp_mask;		/* enum ib_uverbs_qp_semantics_mask */
@@ -2830,6 +2867,28 @@ struct ib_device_ops {
 	struct ib_mr *(*reg_dm_mr)(struct ib_pd *pd, struct ib_dm *dm,
 				   struct ib_dm_mr_attr *attr,
 				   struct uverbs_attr_bundle *attrs);
+	/*
+	 * A job outlives the context that allocated it once another imports
+	 * it, so nothing the driver keeps for it may depend on attrs->context.
+	 * alloc_job refuses a JobID already allocated on the device with
+	 * -EEXIST. job_addr_* may run concurrently on one job; the driver
+	 * serializes them. The sgid_attr of an entry's ah_attr is valid only
+	 * for the job_addr_insert call, so a driver that keeps it takes its
+	 * own reference; core releases one that job_addr_query sets.
+	 */
+	int (*alloc_job)(struct ib_job *job, struct ib_job_attr *attr,
+			 struct uverbs_attr_bundle *attrs);
+	void (*dealloc_job)(struct ib_job *job);
+	int (*query_job)(struct ib_job *job, struct ib_job_attr *attr);
+	int (*job_addr_insert)(struct ib_job *job, u32 index,
+			       struct rdma_ah_attr_ex *ah_attr);
+	int (*job_addr_remove)(struct ib_job *job, u32 index);
+	int (*job_addr_query)(struct ib_job *job, u32 index,
+			      struct rdma_ah_attr_ex *ah_attr);
+	int (*create_jkey)(struct ib_jkey *jkey,
+			   struct uverbs_attr_bundle *attrs);
+	int (*destroy_jkey)(struct ib_jkey *jkey,
+			    struct uverbs_attr_bundle *attrs);
 	int (*create_counters)(struct ib_counters *counters,
 			       struct uverbs_attr_bundle *attrs);
 	int (*destroy_counters)(struct ib_counters *counters);
@@ -2983,6 +3042,8 @@ struct ib_device_ops {
 
 	DECLARE_RDMA_OBJ_SIZE(ib_ah);
 	DECLARE_RDMA_OBJ_SIZE(ib_counters);
+	DECLARE_RDMA_OBJ_SIZE(ib_job);
+	DECLARE_RDMA_OBJ_SIZE(ib_jkey);
 	DECLARE_RDMA_OBJ_SIZE(ib_cq);
 	DECLARE_RDMA_OBJ_SIZE(ib_comp_cntr);
 	DECLARE_RDMA_OBJ_SIZE(ib_dmah);
@@ -3930,6 +3991,10 @@ struct ib_ah *rdma_create_ah(struct ib_pd *pd, struct rdma_ah_attr *ah_attr,
 struct ib_ah *rdma_create_user_ah(struct ib_pd *pd,
 				  struct rdma_ah_init_attr *init_attr,
 				  struct ib_udata *udata);
+
+int rdma_job_addr_insert(struct ib_job *job, u32 index,
+			 struct rdma_ah_attr_ex *ah_attr);
+
 /**
  * ib_get_gids_from_rdma_hdr - Get sgid and dgid from GRH or IPv4 header
  *   work completion.
diff --git a/include/rdma/restrack.h b/include/rdma/restrack.h
index 47fec3083d28..a7d53540da67 100644
--- a/include/rdma/restrack.h
+++ b/include/rdma/restrack.h
@@ -64,6 +64,14 @@ enum rdma_restrack_type {
 	 * @RDMA_RESTRACK_COMP_CNTR: Completion Counter
 	 */
 	RDMA_RESTRACK_COMP_CNTR,
+	/**
+	 * @RDMA_RESTRACK_JOB: Transport job
+	 */
+	RDMA_RESTRACK_JOB,
+	/**
+	 * @RDMA_RESTRACK_JKEY: Job key
+	 */
+	RDMA_RESTRACK_JKEY,
 	/**
 	 * @RDMA_RESTRACK_MAX: Last entry, used for array dclarations
 	 */
diff --git a/include/rdma/uverbs_ioctl.h b/include/rdma/uverbs_ioctl.h
index a920e57ce990..b1fce07f02c4 100644
--- a/include/rdma/uverbs_ioctl.h
+++ b/include/rdma/uverbs_ioctl.h
@@ -147,7 +147,7 @@ enum uapi_radix_data {
 	UVERBS_API_OBJ_KEY_BITS = 6,
 	UVERBS_API_OBJ_KEY_SHIFT =
 		UVERBS_API_METHOD_KEY_BITS + UVERBS_API_METHOD_KEY_SHIFT,
-	UVERBS_API_OBJ_KEY_NUM_CORE = 20,
+	UVERBS_API_OBJ_KEY_NUM_CORE = 23,
 	UVERBS_API_OBJ_KEY_NUM_DRIVER =
 		(1 << UVERBS_API_OBJ_KEY_BITS) - UVERBS_API_OBJ_KEY_NUM_CORE,
 	UVERBS_API_OBJ_KEY_MASK = GENMASK(31, UVERBS_API_OBJ_KEY_SHIFT),
diff --git a/include/uapi/rdma/ib_user_ioctl_cmds.h b/include/uapi/rdma/ib_user_ioctl_cmds.h
index fb746257eb2c..70de1e4001c3 100644
--- a/include/uapi/rdma/ib_user_ioctl_cmds.h
+++ b/include/uapi/rdma/ib_user_ioctl_cmds.h
@@ -58,6 +58,9 @@ enum uverbs_default_objects {
 	UVERBS_OBJECT_DMAH,
 	UVERBS_OBJECT_DMABUF,
 	UVERBS_OBJECT_COMP_CNTR,
+	UVERBS_OBJECT_JOB,
+	UVERBS_OBJECT_JKEY,
+	UVERBS_OBJECT_JOB_FD,
 };
 
 enum {
@@ -495,4 +498,78 @@ enum uverbs_attrs_read_comp_cntr_cmd_attr_ids {
 	UVERBS_ATTR_READ_COMP_CNTR_RESP_VALUE,
 };
 
+enum uverbs_methods_job {
+	UVERBS_METHOD_JOB_ALLOC,
+	UVERBS_METHOD_JOB_DEALLOC,
+	UVERBS_METHOD_JOB_QUERY,
+	UVERBS_METHOD_JOB_ADDR_INSERT,
+	UVERBS_METHOD_JOB_ADDR_REMOVE,
+	UVERBS_METHOD_JOB_ADDR_QUERY,
+	UVERBS_METHOD_JOB_EXPORT,
+	UVERBS_METHOD_JOB_IMPORT,
+};
+
+enum uverbs_attrs_alloc_job_cmd_attr_ids {
+	UVERBS_ATTR_ALLOC_JOB_HANDLE,
+	UVERBS_ATTR_ALLOC_JOB_ID,
+	UVERBS_ATTR_ALLOC_JOB_MAX_ADDR_ENTRIES,
+	UVERBS_ATTR_ALLOC_JOB_PORT_NUM,
+	UVERBS_ATTR_ALLOC_JOB_SGID_INDEX,
+};
+
+enum uverbs_attrs_dealloc_job_cmd_attr_ids {
+	UVERBS_ATTR_DEALLOC_JOB_HANDLE,
+};
+
+enum uverbs_attrs_query_job_cmd_attr_ids {
+	UVERBS_ATTR_QUERY_JOB_HANDLE,
+	UVERBS_ATTR_QUERY_JOB_ID,
+	UVERBS_ATTR_QUERY_JOB_MAX_ADDR_ENTRIES,
+	UVERBS_ATTR_QUERY_JOB_PORT_NUM,
+	UVERBS_ATTR_QUERY_JOB_SGID_INDEX,
+};
+
+enum uverbs_attrs_job_addr_insert_cmd_attr_ids {
+	UVERBS_ATTR_JOB_ADDR_INSERT_HANDLE,
+	UVERBS_ATTR_JOB_ADDR_INSERT_INDEX,
+	UVERBS_ATTR_JOB_ADDR_INSERT_AH_ATTR_EX,
+};
+
+enum uverbs_attrs_job_addr_remove_cmd_attr_ids {
+	UVERBS_ATTR_JOB_ADDR_REMOVE_HANDLE,
+	UVERBS_ATTR_JOB_ADDR_REMOVE_INDEX,
+};
+
+enum uverbs_attrs_job_addr_query_cmd_attr_ids {
+	UVERBS_ATTR_JOB_ADDR_QUERY_HANDLE,
+	UVERBS_ATTR_JOB_ADDR_QUERY_INDEX,
+	UVERBS_ATTR_JOB_ADDR_QUERY_AH_ATTR_EX,
+};
+
+enum uverbs_attrs_export_job_cmd_attr_ids {
+	UVERBS_ATTR_EXPORT_JOB_HANDLE,
+	UVERBS_ATTR_EXPORT_JOB_FD,
+};
+
+enum uverbs_attrs_import_job_cmd_attr_ids {
+	UVERBS_ATTR_IMPORT_JOB_HANDLE,
+	UVERBS_ATTR_IMPORT_JOB_FD,
+};
+
+enum uverbs_methods_jkey {
+	UVERBS_METHOD_JKEY_CREATE,
+	UVERBS_METHOD_JKEY_DESTROY,
+};
+
+enum uverbs_attrs_create_jkey_cmd_attr_ids {
+	UVERBS_ATTR_CREATE_JKEY_HANDLE,
+	UVERBS_ATTR_CREATE_JKEY_JOB_HANDLE,
+	UVERBS_ATTR_CREATE_JKEY_PD_HANDLE,
+	UVERBS_ATTR_CREATE_JKEY_JKEY,
+};
+
+enum uverbs_attrs_destroy_jkey_cmd_attr_ids {
+	UVERBS_ATTR_DESTROY_JKEY_HANDLE,
+};
+
 #endif

-- 
2.56.0

