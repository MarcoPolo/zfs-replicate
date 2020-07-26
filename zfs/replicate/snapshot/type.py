# -*- coding: utf-8 -*-
"""ZFS Snapshot Type."""
from dataclasses import dataclass
from typing import Optional

from ..filesystem import FileSystem


@dataclass
class Snapshot:
    """ZFS Snapshot Type."""

    filesystem: FileSystem
    name: str
    previous: Optional["Snapshot"]
    timestamp: int

    def __eq__(self, other: object) -> bool:
        """Equality of Snapshots."""
        if not isinstance(other, Snapshot):
            raise NotImplementedError

        is_suffix = self.filesystem.name.endswith(other.filesystem.name) or other.filesystem.name.endswith(
            self.filesystem.name,
        )

        return is_suffix and self.name == other.name and self.timestamp == other.timestamp
