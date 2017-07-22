import React from 'react'

import {
	View,
	Button,
	Text
} from 'react-native'

import {
	patch
} from '../../lib/fetcher'

import EditPostInfo from './EditPostInfo'

class EditPost extends React.Component {
	constructor(props){
		super(props)

		this.state = {
			showErrors: false,
			postInfo: this.props.navigation.state.params.postInfo,
		}
	}

	onSave = () => {
		const {goBack} = this.props.navigation

		patch(`/posts/${this.state.postInfo.id}`, {
			post: {
				title: this.state.postInfo.title,
				description: this.state.postInfo.description,
				url: this.state.postInfo.url
			}
		}).then((res) => {
			goBack()
		}).catch(() => alert('there was an error. check your inputs'))
	}

	setPostState = (newKV) => {
		const postInfo = Object.assign({}, this.state.postInfo, newKV)
		this.setState({postInfo})
	}

  render() {
    return (
			<View style={{padding: 50}}>
				<EditPostInfo setPostState={this.setPostState} postInfo={this.state.postInfo} />
				<Button onPress={this.onSave} title="save edits" />
			</View>
		)
  }
}

export default EditPost