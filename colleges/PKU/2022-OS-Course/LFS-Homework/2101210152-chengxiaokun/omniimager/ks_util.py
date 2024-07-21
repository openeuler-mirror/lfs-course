import pykickstart.parser
import pykickstart.sections


class KickstartParser(pykickstart.parser.KickstartParser):
    def setupSections(self):
        pykickstart.parser.KickstartParser.setupSections(self)

    def get_packages(self, dnf_obj):
        packages = set()
        conditional_packages = []

        packages.update(self.handler.packages.packageList)

        for ks_group in self.handler.packages.groupList:
            group_id = ks_group.name

            if ks_group.include == GROUP_REQUIRED:
                include_default = False
                include_optional = False
            elif ks_group.include == GROUP_DEFAULT:
                include_default = True
                include_optional = False
            else:
                include_default = True
                include_optional = True

            group_packages, group_conditional_packages = dnf_obj.comps_wrapper.get_packages_from_group(group_id, include_default=include_default, include_optional=include_optional, include_conditional=True)
            packages.update(group_packages)
            for i in group_conditional_packages:
                if i not in conditional_packages:
                    conditional_packages.append(i)

        return packages, conditional_packages

    def get_excluded_packages(self, dnf_obj):
        excluded = set()
        excluded.update(self.handler.packages.excludedList)

        for ks_group in self.handler.packages.excludedGroupList:
            group_id = ks_group.name
            include_default = False
            include_optional = False

            if ks_group.include == 1:
                include_default = True

            if ks_group.include == 2:
                include_default = True
                include_optional = True

            group_packages, group_conditional_packages = dnf_obj.comps_wrapper.get_packages_from_group(group_id, include_default=include_default, include_optional=include_optional, include_conditional=False)
            excluded.update(group_packages)

        return excluded


HandlerClass = pykickstart.version.returnClassForVersion()


def get_ksparser(ks_path=None):
    """
    Return a kickstart parser instance.
    Read kickstart if ks_path provided.
    """
    ksparser = KickstartParser(HandlerClass())
    if ks_path:
        ksparser.readKickstart(ks_path)
    return ksparser


def get_packages(comps, group):
    for grp in comps.groups:
        if grp.id == group:
            return [pkg.name for pkg in grp.packages]
        else:
            return []
