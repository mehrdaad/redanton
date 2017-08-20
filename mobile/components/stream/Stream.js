import React, { Component } from 'react'
import { View, Button, Text, FlatList, StyleSheet } from 'react-native'

// =============
//    STYLES
// =============

var styles = StyleSheet.create({
  stream: {
    height: '100%'
  },
  streamItem: {
    borderBottomWidth: 0.5,
    borderBottomColor: '#ddd',
    display: 'flex',
    alignItems: 'flex-start'
  },
  title: {
    flex: 1
  },
  details: {
    flex: 1,
    flexDirection: 'row'
  },
  channel: {
    paddingLeft: 10,
    paddingRight: 10
  },
  action: {
    paddingLeft: 10,
    paddingRight: 10
  },
  empty: {
    alignItems: 'center',
    padding: 50
  }
})

// =============
//   CHILDREN
// =============

const StreamItem = (props) => {
  return (
    <View style={styles.streamItem}>
      <View style={styles.title}>
        <Button
          onPress={() => props.navigate('Post', {post: props.post})}
          title={props.post.title}
        />
      </View>
      <View style={styles.details}>
        <View style={styles.channel}>
          <Text>In Channel: {props.chanName}</Text>
        </View>
        <View style={styles.action}>
          <Text>Posted By: <Text>{props.posterName}</Text> </Text>
        </View>
      </View>
    </View>
  )
}

// =============
//     MAIN
// =============

class Stream extends Component {

  get hasNoConent () {
    return !this.props.content || this.props.content.length === 0
  }

  renderEmpty () {
    return (
      <View style={styles.empty}>
        <Text> There's nothing here </Text>
        <Text> Add a post to get started. </Text>
      </View>
    )
  }

  renderPostLink = (datum) => {
    const { navigate } = this.props.navigation
    // TODO: thread in poster info
    const poster = {name: 'Mike'}
    const chan = this.props.channels[datum.item.channel_id] || {}
    return (
      <StreamItem
        navigate={navigate}
        post={datum.item}
        posterName={poster.name}
        chanName={chan.name}/>
    )
  }

  render() {
    if (this.hasNoConent) return this.renderEmpty()

    return (
      <View style={styles.stream}>
        <FlatList
          data={this.props.content}
          renderItem={this.renderPostLink}
          keyExtractor={(item) => item.id}
        />
      </View>
    )
  }
}

export default Stream
