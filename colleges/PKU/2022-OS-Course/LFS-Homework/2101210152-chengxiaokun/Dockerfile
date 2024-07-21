FROM python:3.8.12 as BUILDER
LABEL maintainer="tommylike<tommylikehu@gmail.com>"
WORKDIR /omni-imager
COPY . /omni-imager
RUN pip3 install -r requirements.txt && python3 setup.py install bdist_wheel

FROM openeuler/openeuler:21.09
WORKDIR /omni-imager
COPY --chown=root --from=BUILDER /omni-imager/dist/ .
COPY --chown=root ./etc/ /etc/
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3 get-pip.py && rm get-pip.py && pip3 install *
RUN yum -y update && yum -y install createrepo dnf genisoimage
RUN yum -y update && yum -y install  dnf-plugins-core cpio gzip tar
ENTRYPOINT ["omni-imager"]
