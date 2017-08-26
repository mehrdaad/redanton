import React, { Component } from 'react'
import {
  View,
  Button,
  WebView
 } from 'react-native'

import { confirmMessage } from '../../lib/uiActions'

import { deletePost } from '../../data/posts'

import { connect } from 'react-redux'

const EditPostButton = (props) => (
  <Button title="Edit" onPress={() => props.navigation.navigate('EditPost', {postInfo: props.post})} />
)

const DeletePostButton = (props) => (
  <Button title="Remove" onPress={() => {
    confirmMessage('Remove Post', 'Are you sure?', props.removePost)
  }} />
)

class Post extends Component {
  get post() {
    return this.props.post
  }

  get uri () {
    if (!/^(?:f|ht)tps?\:\/\//.test(this.post.url)) {
      return 'http://' + this.post.url
    }
    return this.post.url
  }

  goToChat = () => {
    this.props.navigation.navigate('PostChat', {post: this.post})
  }

  renderEdit () {
    if ( this.props.userIsOwner ) {
      return (
        <EditPostButton navigation={this.props.navigation} post={this.post} />
      )
    }
  }

  renderDelete () {
    if ( this.props.userIsOwner ) {
      return (
        <DeletePostButton removePost={this.removePost}/>
      )
    }
  }
  // TODO: make these into flex
  render() {
    return (
      <View style={{
        width: '100%',
        height: '100%'
      }}>
        <WebView
          style={{
            width: '100%',
            height: '90%'
          }}
          startInLoadingState
          automaticallyAdjustContentInsets={true}
          javaScriptEnabled={true}
          domStorageEnabled={true}
          scalesPageToFit={true}
          source={{uri: this.uri}}
        />
        <View style={{
          width: '100%',
          height: '10%',
          display: 'flex',
          flexDirection: 'row',
          justifyContent: 'space-around',
          alignItems: 'center'
        }}>
          {this.renderDelete()}
          {this.renderEdit()}
          <Button onPress={this.goToChat} title="Chat >" />
        </View>
      </View>
    )
  }
}

// ===============
//   CONNECTION
// ===============

const mapStateToProps = (state, props) => {
  const post = state.posts[props.navigation.state.params.post.id]
  const currentUserId = state.auth.currentUser.id
  const userIsOwner = post && post.user_id === currentUserId
  return { post, userIsOwner }
}

export default connect(
  mapStateToProps,
  { deletePost }
)(Post)