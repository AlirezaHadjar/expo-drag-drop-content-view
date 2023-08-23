package expo.modules.dragdropcontentview

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ExpoDragDropContentViewModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("ExpoDragDropContentView")

    View(ExpoDragDropContentView::class) {}
  }
}
