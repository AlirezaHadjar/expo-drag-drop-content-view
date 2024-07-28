package expo.modules.dragdropcontentview.records

import expo.modules.kotlin.records.Field
import expo.modules.kotlin.types.Enumerable
import expo.modules.kotlin.records.Record

enum class DraggableType(val value: String) : Enumerable {
    IMAGE("image"),
    VIDEO("video"),
    TEXT("text"),
    FILE("file");
}

data class DraggableItem(@Field val type: DraggableType, @Field val value: String): Record
