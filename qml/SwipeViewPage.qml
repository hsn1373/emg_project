import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    // Don't show the item when the StackView that contains us
    // is being popped off the stack, as we use an x animation
    // and hence would show pages that we shouldn't since we
    // also don't have our own background.
    visible: SwipeView.isCurrentItem || (SwipeView.view.contentItem.moving && (SwipeView.isPreviousItem || SwipeView.isNextItem))
//    visible: SwipeView.isCurrentItem
}
