import React, { PureComponent } from 'react'
import { ScrollView, View } from 'react-native'
import { connect } from 'react-redux'
import { compose } from 'redux'

import { spacing } from '../styleConstants'

import {
  validatePresence,
  validateLength,
  combineValidations
} from '../../lib/validations'
import withValidation from '../helpers/withValidation'

import { deletePost, updatePost } from '../../data/posts'
import { postWithTagNames } from '../../data/postsTags'

import ActionButton from '../ui/ActionButton'
import EditPostInfo from './EditPostInfo'
import DeletePostButton from './DeletePostButton'
import Footer from '../ui/Footer'

// ===============
//   VALIDATIONS
// ===============

const validations = {
  title: combineValidations(
    validatePresence('you must have a title'),
    validateLength({min: 1, max: 150, msg: 'must be between 1 and 150 characters'})
  )
}

// ===============
//    PRESENTER
// ===============

class EditPost extends PureComponent {
	constructor(props){
		super(props)

		this.state = {
			showErrors: false,
			postInfo: this.props.withTagNames(
        this.props.navigation.state.params.postInfo
      )
		}
  }

  removePost = () => {
    this.props.deletePost(this.state.postInfo.id, this.props.navigation.goBack)
  }

	savePost = () => {
		const {goBack} = this.props.navigation
    this.props.updatePost(this.state.postInfo, () => goBack())
  }

  onSaveClick = () => {
    this.props.unlessErrors(
      {title: this.state.postInfo.title},
      this.savePost
    )
  }

	setPostState = (newKV) => {
		const postInfo = Object.assign({}, this.state.postInfo, newKV)
		this.setState({postInfo})
	}

  render() {
    return (
      <View>
        <ScrollView style={{padding: spacing.container, height: '90%'}}>
          <EditPostInfo
            errorFor={this.props.errorFor}
            setPostState={this.setPostState}
            postInfo={this.state.postInfo}
          />
          <ActionButton onPress={this.onSaveClick}>
            save edits
          </ActionButton>
        </ScrollView>
        <Footer>
          <DeletePostButton removePost={this.removePost} />
        </Footer>
			</View>
		)
  }
}

// ===============
//   CONNECTION
// ===============

const dispatchableActions = {
  deletePost,
  updatePost,
}

const mapStateToProps = (state) => {
  return {
    withTagNames: (post) => postWithTagNames(state, post)
  }
}

export default compose(
  withValidation(validations),
  connect(mapStateToProps, dispatchableActions)
)(EditPost)